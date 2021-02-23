import 'dart:convert';
import 'dart:io';

import 'package:appcore/core/api_user.dart';
import 'package:appcore/requests/requests.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

import 'datastore.dart';
import 'core_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'core_browser.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'core_mobile.dart';

part 'api_state.dart';

const _dataKeyTime = "__time";
const _dataKeyClearData = "__clearData";
const _metadataKeyLastSyncTime = "lastSyncTime";
const _paramKeyLastSyncTime = "lastSyncTime";

const _gidShift = 10; // Must match up with the server

const _boxNamePersist = 'apiMetadata';
const _boxNameRequestQueue = 'apiRequestQueue';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';
const _keyUsedIds = 'usedIds';
const _keyActionsPaused = 'actionsPaused';

abstract class ApiCubit<D extends Datastore, U extends ApiUser>
    extends Cubit<ApiState<U>> {
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

    datastore.initialize();
    _initialize(_fixedBaseApiUrl);
  }

  @override
  void onChange(Change<ApiState> change) {
    super.onChange(change);
    if (!change.nextState.ready) return;

    bool sendNextRequest = false;
    Map<String, dynamic> changes = {};
    if (change.currentState.baseApiUrl != change.nextState.baseApiUrl) {
      debugPrint('baseApiUrl: ${change.nextState.baseApiUrl}');
      changes[_keyBaseApiUrl] = change.nextState.baseApiUrl.toString();
    }

    if (change.currentState.loginSession != change.nextState.loginSession) {
      changes[_keyLoginSession] = change.nextState.loginSession?.toJson();
      if (change.currentState.loginSession?.gid !=
          change.nextState.loginSession?.gid) {
        changes[_keyUsedIds] = 0;
      }
      if (change.nextState.loginSession?.user
              ?.reloadFullData(change.currentState.loginSession?.user) ??
          true) {
        datastore.putMetadata(_metadataKeyLastSyncTime, 0);
      }
      sendNextRequest = true;
      if (change.nextState.loginSession == null) {
        _socketFuture
            ?.timeout(Duration.zero, onTimeout: () => null)
            ?.then((socket) => socket?.close(1000, "logout"));
        _socketFuture = null;
      }
    }

    if (change.currentState.actionQueueState.paused !=
        change.nextState.actionQueueState.paused) {
      debugPrint('actionsPaused: ${change.nextState.actionQueueState.paused}');
      changes[_keyActionsPaused] = change.nextState.actionQueueState.paused;
      sendNextRequest = true;
    } else if (change.currentState.actionQueueState.actions !=
        change.nextState.actionQueueState.actions) {
      sendNextRequest = true;
    }

    if (changes.isNotEmpty) {
      _persist.putAll(changes);
    }
    if (sendNextRequest) {
      Future.microtask(() => _sendNextRequest());
    }
  }

  Future<void> _initialize(Uri baseApiUrl) async {
    await datastore.ready;
    _requests = await Hive.openBox(_boxNameRequestQueue);
    _persist = await Hive.openBox(_boxNamePersist);

    emit(ApiState(
      ready: true,
      baseApiUrl: baseApiUrl ??
          Uri.tryParse(_persist.get(_keyBaseApiUrl, defaultValue: '')),
      loginSession:
          LoginSession.fromJson(_persist.get(_keyLoginSession), _parseUser),
      actionQueueState: ActionQueueState(
        actions: _requests.values.toList(growable: false),
        paused: _persist.get(_keyActionsPaused, defaultValue: false),
      ),
    ));
    debugPrint('[api] Ready');
  }

  Future<void> logout() async {
    debugPrint('[api] Logging Out');

    emit(state.copyWith(
        ready: false, loginSession: null, allowNullLoginSession: true));

    datastore.wipe();
    await Hive.deleteBoxFromDisk(_boxNameRequestQueue);
    await Hive.deleteBoxFromDisk(_boxNamePersist);

    // * Wait for any ongoing connections to finish
    while (state.actionQueueState.submitting ||
        state.fetchState.fetching ||
        state.fetchState.connected) {
      await firstWhere((state) =>
          !state.actionQueueState.submitting &&
          !state.fetchState.fetching &&
          !state.fetchState.connected);
    }

    await _initialize(state.baseApiUrl);
  }

  bool get isSignedIn => state.loginSession != null;

  bool get canChangeBaseApiUrl => _fixedBaseApiUrl == null;
  bool get canLogIn =>
      state.ready &&
      !isSignedIn &&
      state.baseApiUrl != null &&
      (!kIsWeb || state.baseApiUrl.hasAuthority);

  set baseApiUrl(Uri value) {
    emit(state.copyWith(baseApiUrl: value));
  }

  Map<String, String> generateAuthHeaders() {
    return {
      'Authorization': 'SessionId ${state.loginSession.sessionId}',
    };
  }

  String createUrl(String path) {
    return createUriBuilder(path).toString();
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

  Map<String, String> createLastSyncParams({bool incremental = true}) =>
      incremental
          ? <String, String>{
              _paramKeyLastSyncTime: datastore
                  .getMetadata(_metadataKeyLastSyncTime, defaultValue: 0)
                  .toString(),
            }
          : <String, String>{};

  Future<String> sendRequest(BaseRequest request,
      {bool authRequired = true}) async {
    debugPrint('[api] Sending request to ${request.url}');
    if (authRequired) {
      request.headers['Authorization'] =
          'SessionId ${state.loginSession.sessionId}';
    }
    try {
      final response = await _client.send(request);
      String responseString = await response.stream.bytesToString();

      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(responseString, authRequired: authRequired);
        return null;
      } else {
        return responseString;
      }
    } catch (e) {
      if (e is SocketException) {
        return 'Server Unreachable';
      } else {
        return e.toString();
      }
    }
  }

  Future<void> parseResponseString(String responseString,
      {bool authRequired = true}) async {
    if (responseString.isNotEmpty) {
      final responseMap = json.decode(responseString) as Map<String, dynamic>;
      await parseResponseMap(responseMap, authRequired: authRequired);
    }
  }

  Future<bool> parseResponseMap(Map<String, dynamic> response,
      {bool authRequired = true}) async {
    if (authRequired && !isSignedIn) return false;
    debugPrint('[api] Parsing response');
    LoginSession<U> parsedSession;
    if (response.containsKey('session')) {
      debugPrint('[api] Parsing session');
      final sessionMap = response['session'] as Map<String, dynamic>;
      parsedSession = LoginSession.fromMap(sessionMap, _parseUser);
      if (parsedSession == null) return false;
    }

    if (response.containsKey('data')) {
      debugPrint('[api] Parsing data');
      final data = response['data'] as Map<String, dynamic>;
      if (data.containsKey(_dataKeyClearData) && data[_dataKeyClearData]) {
        await datastore.wipe();
        print("[api] Clearing Data");
      }
      await datastore.parseData(data);

      debugPrint('[api] Data Parsed');
      if (data.containsKey(_dataKeyTime)) {
        datastore.putMetadata(
            _metadataKeyLastSyncTime, data[_dataKeyTime] as int);
      }
    }
    if (response.containsKey('debug')) {
      debugPrint(response['debug'].toString());
    }

    if (parsedSession != null) {
      emit(state.copyWith(loginSession: parsedSession));
    }
    debugPrint('[api] Response parsed');
    return true;
  }

  Future<void> enqueueOfflineAction(ApiAction action) async {
    if (!state.ready) return;
    debugPrint(
        '[api] Action enqueued: ${action.runtimeType} | ${action.generateDescription(this)}');
    action.applyOptimisticUpdate(this);
    // await _actions.add(action);
  }

  Future<void> enqueue(ApiRequest request) async {
    if (!state.ready) return;
    debugPrint(
        '[api] Request enqueued: ${request.endpoint} | ${request.description}');
    await _requests.add(request);
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithActions(
        _requests.values,
      ),
    ));
  }

  Future<void> deleteRequestAt(int index) async {
    if (!state.ready) return;
    if (index >= _requests.length) return;

    if (index == 0 && state.actionQueueState.submitting) return;

    if (kDebugMode) {
      final request = _requests.getAt(index);
      debugPrint(
          '[api] Deleting request: ${request.endpoint} | ${request.description}');
    }

    await _requests.deleteAt(index);
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithActions(
        _requests.values,
        resetError: index == 0,
      ),
    ));
  }

  Future<void> deleteRequest(ApiRequest request) async {
    if (!state.ready) return;

    bool isFirstRequest = request == _requests.getAt(0);
    if (isFirstRequest && state.actionQueueState.submitting) return;

    if (kDebugMode) {
      debugPrint(
          '[api] Deleting request: ${request.endpoint} | ${request.description}');
    }

    await request.delete();
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithActions(
        _requests.values,
        resetError: isFirstRequest,
      ),
    ));
  }

  void pause() {
    debugPrint('[api] Pausing');
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithPaused(true),
    ));
  }

  void resume() {
    debugPrint('[api] Resuming');
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithPaused(false),
    ));
  }

  void _sendNextRequest() async {
    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }

    if (!isSignedIn ||
        _requests.isEmpty ||
        state.actionQueueState.paused ||
        state.actionQueueState.submitting) {
      return;
    }

    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithSubmitting(true, null),
    ));

    final request = _requests.getAt(0);
    final uriBuilder = createUriBuilder(request.endpoint);
    uriBuilder.queryParameters.addAll(createLastSyncParams());
    final httpRequest = await request.createRequest(uriBuilder.build());

    final error = await sendRequest(httpRequest);
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithSubmitting(
        false,
        error,
      ),
    ));
    if (error == null) {
      deleteRequestAt(0);
    }
  }

  void fetchUpdates({bool incremental = true}) async {
    debugPrint('[api] Fetching Updates');

    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }
    if (!isSignedIn ||
        state.fetchState.fetching ||
        state.fetchState.connected) {
      return;
    }

    emit(state.copyWith(
      fetchState: state.fetchState.copyWith(fetching: true),
    ));

    final uriBuilder = createUriBuilder('/v1/sync');
    uriBuilder.queryParameters
        .addAll(createLastSyncParams(incremental: incremental));
    final httpRequest = Request('get', uriBuilder.build());

    final error = await sendRequest(httpRequest, authRequired: true);
    emit(state.copyWith(
      fetchState: state.fetchState.copyWith(
        fetching: false,
        error: error,
      ),
    ));
  }

  void establishTickerSocket() async {
    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }
    if (!isSignedIn || state.fetchState.connected) {
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
    emit(state.copyWith(
      fetchState: state.fetchState.copyWith(connected: true),
    ));
    _socketFuture.then((socket) {
      debugPrint('[api] Update socket created');
      return socket.listen((message) {
        parseResponseString(message);
      }, onError: (err) {
        debugPrint("[api] Update socket error: $err");
        _socketFuture = null;
        emit(state.copyWith(
          fetchState: state.fetchState.copyWith(connected: false),
        ));
      }, onDone: () {
        debugPrint(
            '[api] Update socket closed: ${socket.closeCode}, ${socket.closeReason}');
        _socketFuture = null;
        emit(state.copyWith(
          fetchState: state.fetchState.copyWith(connected: false),
        ));
      });
    }, onError: (err) {
      debugPrint("[api] Update socket error: $err");
      _socketFuture = null;
      emit(state.copyWith(
        fetchState: state.fetchState.copyWith(connected: false),
      ));
    });
  }
}
