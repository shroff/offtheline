import 'dart:convert';
import 'dart:io';

import 'package:appcore/core/api_user.dart';
import 'package:appcore/requests/requests.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uri/uri.dart';

import 'datastore.dart';
import 'core_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'core_browser.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'core_mobile.dart';

import 'api_state.dart';

const _dataKeyTime = "__time";
const _dataKeyClearData = "__clearData";
const _metadataKeyLastSyncTime = "lastSyncTime";
const _paramKeyLastSyncTime = "lastSyncTime";
const _metadataKeyLastSyncPermissions = "lastSyncPermissions";
const _paramKeyLastSyncPermissions = "lastSyncPermissions";

const _gidShift = 10; // Must match up with the server

const _boxNamePersist = 'apiMetadata';
const _boxNameRequestQueue = 'apiRequestQueue';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';
const _keyUsedIds = 'usedIds';
const _keyActionsPaused = 'actionsPaused';

class ApiCubit<D extends Datastore, U extends ApiUser> extends Cubit<ApiState> {
  final D datastore;

  Future<WebSocket> _socketFuture;
  Box _persist;
  Box<ApiRequest> _requests;
  final BaseClient _client = createHttpClient();
  final ApiUserParser<U> _parseUser;
  final Uri _fixedBaseApiUrl;

  ApiCubit(
    this.datastore,
    this._parseUser, {
    Uri fixedBaseApiUrl,
  })  : this._fixedBaseApiUrl = fixedBaseApiUrl,
        super(const ApiState(ready: false)) {
    debugPrint('[api] Initializing');
    Hive.registerAdapter(UploadApiRequestAdapter());
    Hive.registerAdapter(SimpleApiRequestAdapter());

    _initialize(_fixedBaseApiUrl);
  }

  @override
  void onChange(Change<ApiState> change) {
    super.onChange(change);
    Map<String, dynamic> changes = {};
    if (change.currentState.baseApiUrl != change.nextState.baseApiUrl) {
      debugPrint('baseApiUrl: ${change.nextState.baseApiUrl}');
      changes[_keyBaseApiUrl] = change.nextState.baseApiUrl.toString();
    }

    if (change.currentState.loginSession != change.nextState.loginSession) {
      changes[_keyLoginSession] = change.nextState.loginSession?.toJson();
      debugPrint('Login Session: ${change.nextState.loginSession?.toString()}');
      if (change.currentState.loginSession?.gid !=
          change.nextState.loginSession?.gid) {
        debugPrint('usedIds: 0');
        changes[_keyUsedIds] = 0;
      }
    }

    if (change.currentState.actionsPaused != change.nextState.actionsPaused) {
      debugPrint('actionsPaused: ${change.nextState.actionsPaused}');
      changes[_keyActionsPaused] = change.nextState.actionsPaused;
    }

    if (changes.isNotEmpty) {
      _persist.putAll(changes);
    }
  }

  Future<void> _initialize(Uri baseApiUrl) async {
    await datastore.ready;
    _requests = await Hive.openBox(_boxNameRequestQueue);
    _persist = await Hive.openBox(_boxNamePersist);

    emit(state.copyWith(
      ready: true,
      baseApiUrl: baseApiUrl ?? Uri.tryParse(_persist.get(_keyBaseApiUrl)),
      loginSession:
          LoginSession.fromJson(_persist.get(_keyLoginSession), _parseUser),
      actionsPaused: _persist.get(_keyActionsPaused, defaultValue: false),
      actions: _requests.values.toList(growable: false),
    ));
    debugPrint('[api] Ready');
    sendNextRequest();
  }

  Future<void> signOut() async {
    debugPrint('[api] Clearing');

    emit(state.copyWith(ready: false));

    // * Wait for any ongoing connections to finish
    while (state.actionSubmitting ||
        state.fetchingUpdates ||
        state.socketConnected) {
      await firstWhere((state) =>
          !state.actionSubmitting &&
          !state.fetchingUpdates &&
          !state.socketConnected);
    }
    await datastore.clear();

    await Hive.deleteBoxFromDisk(_boxNameRequestQueue);
    await Hive.deleteBoxFromDisk(_boxNamePersist);
    await _initialize(state.baseApiUrl);
  }

  bool get isSignedIn => state.loginSession != null;

  bool get canChangeApiBaseUrl => _fixedBaseApiUrl == null;

  set serverUri(Uri value) {
    emit(state.copyWith(baseApiUrl: value));
  }

  String createUrl(String path) {
    return '${state.baseApiUrl}$path';
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(state.baseApiUrl);
    builder.path += path;
    return builder;
  }

  Future<int> generateNextId() async {
    if (state.loginSession == null) return null;
    final usedIds = _persist.get(_keyUsedIds, defaultValue: 0);
    final nextId = usedIds | (state.loginSession.gid << _gidShift);
    await _persist.put(_keyUsedIds, usedIds + 1);
    return nextId;
  }

  Future<StreamedResponse> sendAuthenticatedRequest(BaseRequest request) {
    request.headers['Authorization'] = 'SessionId $state.sessionId';
    return _client.send(request);
  }

  Map<String, String> createLastSyncParams({bool incremental = true}) =>
      incremental
          ? <String, String>{
              _paramKeyLastSyncTime: datastore
                  .getMetadata(_metadataKeyLastSyncTime, defaultValue: 0)
                  .toString(),
              _paramKeyLastSyncPermissions: datastore
                  .getMetadata(_metadataKeyLastSyncPermissions, defaultValue: 0)
                  .toString(),
            }
          : <String, String>{};

  Future<String> loginWithGoogle(
    String email,
    String idToken,
  ) async {
    debugPrint('[api] Google Login');
    if (state.loginSession != null) {
      return "Already Logged In";
    }
    if (idToken?.isEmpty ?? true) {
      return "No ID Token given for Google login";
    }
    final request =
        Request('post', Uri.parse(createUrl('/v1/login/google-id-token')));
    request.headers['Authorization'] = 'Bearer $idToken';
    return sendLoginRequest(request);
  }

  Future<String> loginWithSessionId(String sessionId) async {
    debugPrint('[api] SessionID Login');
    if (state.loginSession != null) {
      return "Already Logged In";
    }
    final request = Request('get', Uri.parse(createUrl('/v1/sync')));
    request.headers['Authorization'] = 'SessionId $sessionId';
    return sendLoginRequest(request);
  }

  Future<String> sendLoginRequest(Request request) async {
    debugPrint('[api] Sending login request to ${request.url}');
    await datastore.clear();

    try {
      final response = await _client.send(request);
      if (response.statusCode == 200) {
        await parseResponseString(await response.stream.bytesToString());
        debugPrint("[api] Login Success");

        return null;
      } else {
        return response.stream.bytesToString();
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        debugPrint(e.toString());
        return "Server Unreachable";
      } else {
        return e.toString();
      }
    }
  }

  Future<void> parseResponseString(String responseString) async {
    if (responseString.isNotEmpty) {
      final responseMap = json.decode(responseString) as Map<String, dynamic>;
      await parseResponseMap(responseMap);
    }
  }

  Future<bool> parseResponseMap(Map<String, dynamic> response) async {
    debugPrint('[api] Parsing response');
    if (response.containsKey('session')) {
      debugPrint('[api] Parsing session');
      final sessionMap = response['session'] as Map<String, dynamic>;
      final session = LoginSession.fromMap(sessionMap, _parseUser);
      if (session == null) return false;
      emit(state.copyWith(loginSession: session));
    }

    if (response.containsKey('data')) {
      debugPrint('[api] Parsing data');
      final data = response['data'] as Map<String, dynamic>;
      if (data.containsKey(_dataKeyClearData) && data[_dataKeyClearData]) {
        await datastore.clear();
        print("Clearing Data");
      }
      await datastore.parseData(data);

      debugPrint('[api] Data Parsed');
      if (data.containsKey(_dataKeyTime)) {
        datastore.putMetadata(
            _metadataKeyLastSyncTime, data[_dataKeyTime] as int);
        datastore.putMetadata(_metadataKeyLastSyncPermissions,
            state.loginSession.user.permissions);
      }
    }
    if (response.containsKey('debug')) {
      debugPrint(response['debug'].toString());
    }
    debugPrint('[api] Response parsed');
    return true;
  }

  Future<void> enqueue(ApiRequest request) async {
    if (!state.ready) return;
    debugPrint(
        '[api] Request enqueued: ${request.endpoint} | ${request.description}');
    await _requests.add(request);
    emit(state.copyWith(actions: _requests.values));
    sendNextRequest();
  }

  Future<void> deleteRequestAt(int index) async {
    if (!state.ready) return;
    if (index >= _requests.length) return;

    if (index == 0 && state.actionSubmitting) return;

    if (kDebugMode) {
      final request = _requests.getAt(index);
      debugPrint(
          '[api] Deleting request: ${request.endpoint} | ${request.description}');
    }

    await _requests.deleteAt(index);
    emit(state.copyWith(
      actions: _requests.values,
      actionError: index == 0 ? '' : null,
    ));
    sendNextRequest();
  }

  Future<void> deleteRequest(ApiRequest request) async {
    if (!state.ready) return;

    bool isFirstRequest = request == _requests.getAt(0);
    if (isFirstRequest && state.actionSubmitting) return;

    if (kDebugMode) {
      debugPrint(
          '[api] Deleting request: ${request.endpoint} | ${request.description}');
    }

    await request.delete();
    emit(state.copyWith(
      actions: _requests.values,
      actionError: isFirstRequest ? '' : null,
    ));
    sendNextRequest();
  }

  void pause() {
    debugPrint('[api] Pausing');
    emit(state.copyWith(actionsPaused: true));
  }

  void resume() {
    debugPrint('[api] Resuming');
    emit(state.copyWith(actionsPaused: false));
    sendNextRequest();
  }

  void sendNextRequest() async {
    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }

    if (!isSignedIn ||
        _requests.isEmpty ||
        state.actionsPaused ||
        state.actionSubmitting) {
      return;
    }

    emit(state.copyWith(actionSubmitting: true));
    final request = _requests.getAt(0);

    final uriBuilder = createUriBuilder(request.endpoint);
    uriBuilder.queryParameters.addAll(createLastSyncParams());
    final httpRequest = await request.createRequest(uriBuilder.build());

    try {
      final response = await sendAuthenticatedRequest(httpRequest);
      String responseString = await response.stream.bytesToString();

      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(responseString);
        emit(state.copyWith(actionSubmitting: false, actionError: ''));
        deleteRequest(request);
      } else {
        emit(state.copyWith(
            actionSubmitting: false, actionError: responseString));
      }
    } catch (e) {
      if (e is SocketException) {
        emit(state.copyWith(
            actionSubmitting: false, actionError: 'Server Unreachable'));
      } else {
        emit(
            state.copyWith(actionSubmitting: false, actionError: e.toString()));
      }
    }
  }

  void fetchUpdates({bool incremental = true}) async {
    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }
    if (!isSignedIn || state.fetchingUpdates || state.socketConnected) {
      return;
    }

    emit(state.copyWith(fetchingUpdates: true));
    debugPrint('[api] Fetching Updates');

    final uriBuilder = createUriBuilder('/v1/sync');
    uriBuilder.queryParameters
        .addAll(createLastSyncParams(incremental: incremental));
    final httpRequest = Request('get', uriBuilder.build());

    try {
      final response = await sendAuthenticatedRequest(httpRequest);
      String responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        await parseResponseString(responseString);
        emit(state.copyWith(fetchingUpdates: false, fetchError: ''));
      } else {
        emit(
            state.copyWith(fetchingUpdates: false, fetchError: responseString));
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        emit(state.copyWith(
            fetchingUpdates: false, fetchError: 'Server Unreachable'));
      } else {
        emit(state.copyWith(fetchingUpdates: false, fetchError: e.toString()));
      }
    }
  }

  void establishTickerSocket() async {
    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }
    if (!isSignedIn || state.socketConnected) {
      return;
    }

    final uriBuilder = createUriBuilder('/v1/ticker');
    uriBuilder.scheme = uriBuilder.scheme == "https" ? "wss" : "ws";
    uriBuilder.queryParameters.addAll(createLastSyncParams(incremental: true));

    // ignore: close_sinks
    _socketFuture = WebSocket.connect(
      uriBuilder.toString(),
      headers: {"Authorization": 'SessionId ${state.loginSession.sessionId}'},
    );
    emit(state.copyWith(socketConnected: true));
    _socketFuture.then((socket) {
      debugPrint('[api] Ticker channel created');
      return socket.listen((message) {
        debugPrint("[api] Ticker message");
        parseResponseString(message);
      }, onError: (err) {
        debugPrint("[api] Ticker error: $err");
        _socketFuture = null;
        emit(state.copyWith(socketConnected: false));
      }, onDone: () {
        debugPrint(
            '[api] Ticker closed: ${socket.closeCode}, ${socket.closeReason}');
        _socketFuture = null;
        emit(state.copyWith(socketConnected: false));
      });
    }, onError: (err) {
      debugPrint("[api] Ticker socket error: $err");
      _socketFuture = null;
      emit(state.copyWith(socketConnected: false));
    });
  }
}
