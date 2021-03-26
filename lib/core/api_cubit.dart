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
const _boxNameActionQueue = 'apiActionQueue';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';
const _keyUsedIds = 'usedIds';
const _keyActionsPaused = 'actionsPaused';

const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

typedef ApiActionDeserializer<D extends Datastore, U extends ApiUser,
        T extends ApiCubit<D, U, T>>
    = ApiAction<D, U, T> Function(Map<String, dynamic> props, dynamic data);

abstract class ApiCubit<D extends Datastore, U extends ApiUser,
    T extends ApiCubit<D, U, T>> extends Cubit<ApiState<D, U, T>> {
  final BaseClient _client = createHttpClient();
  final D datastore;
  final ApiUserParser<U> _parseUser;
  final Uri? _fixedBaseApiUrl;
  final String? tickerPath;

  late Box _persist;
  late Box<Map> _actions;
  Future<WebSocket>? _socketFuture;

  Map<String, ApiActionDeserializer<D, U, T>> get deserializers;

  ApiCubit(
    this.datastore,
    this._parseUser, {
    Uri? fixedBaseApiUrl,
    this.tickerPath,
  })  : this._fixedBaseApiUrl = fixedBaseApiUrl,
        super(ApiState.init()) {
    debugPrint('[api] Initializing');
    Hive.registerAdapter(UploadApiRequestAdapter());
    Hive.registerAdapter(SimpleApiRequestAdapter());

    datastore.initialize();
    _initialize(_fixedBaseApiUrl);
  }

  @override
  void onChange(Change<ApiState<D, U, T>> change) {
    super.onChange(change);
    if (!change.nextState.ready) return;

    Map<String, dynamic> changes = {};
    if (change.currentState.baseApiUrl != change.nextState.baseApiUrl) {
      changes[_keyBaseApiUrl] = change.nextState.baseApiUrl.toString();
    }

    if (change.currentState.ready) {
      if (change.currentState.actionQueueState !=
          change.nextState.actionQueueState) {
        if (change.currentState.actionQueueState.paused !=
            change.nextState.actionQueueState.paused) {
          changes[_keyActionsPaused] = change.nextState.actionQueueState.paused;
        }
        Future.microtask(() {
          _sendNextRequest();
        });
      }

      if (change.currentState.loginSession != change.nextState.loginSession) {
        changes[_keyLoginSession] = change.nextState.loginSession?.toJson();
        if (change.nextState.loginSession?.user
                .reloadFullData(change.currentState.loginSession?.user) ??
            true) {
          datastore.putMetadata(_metadataKeyLastSyncTime, 0);
        }
      }
    } else {
      // Login or logout
      if (change.nextState.loginSession == null) {
        closeTickerSocket("logout");
      } else {
        Future.microtask(() {
          establishTickerSocket();
          _sendNextRequest();
        });
      }
    }

    if (changes.isNotEmpty) {
      _persist.putAll(changes);
    }
  }

  Future<void> _initialize(Uri? baseApiUrl) async {
    await datastore.ready;
    _persist = await Hive.openBox(_boxNamePersist);
    _actions = await Hive.openBox(_boxNameActionQueue);

    emit(ApiState._(
      ready: true,
      baseApiUrl: baseApiUrl ??
          Uri.tryParse(_persist.get(_keyBaseApiUrl, defaultValue: ''))!,
      loginSession:
          LoginSession.fromJson(_persist.get(_keyLoginSession), _parseUser),
      actionQueueState: ActionQueueState<D, U, T>(
        actions:
            _actions.values.map((actionMap) => _deserializeAction(actionMap)),
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
    await Hive.deleteBoxFromDisk(_boxNameActionQueue);
    await Hive.deleteBoxFromDisk(_boxNamePersist);

    // * Wait for any ongoing connections to finish
    while (state.actionQueueState.submitting ||
        state.fetchState.fetching ||
        state.fetchState.connected) {
      await stream.firstWhere((state) =>
          !state.actionQueueState.submitting &&
          !state.fetchState.fetching &&
          !state.fetchState.connected);
    }

    await _initialize(state.baseApiUrl);
  }

  bool get isSignedIn => state.loginSession != null;

  bool get canChangeBaseApiUrl => _fixedBaseApiUrl == null;
  bool get canLogIn =>
      state.ready && !isSignedIn && (!kIsWeb || state.baseApiUrl.hasAuthority);

  set baseApiUrl(Uri value) {
    emit(state.copyWith(baseApiUrl: value));
  }

  Map<String, String> generateAuthHeaders() {
    return state.loginSession == null
        ? const {}
        : {
            'Authorization': 'SessionId ${state.loginSession!.sessionId}',
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

  Future<int?> generateNextId() async {
    if (state.loginSession == null) return null;
    final usedIds = _persist.get(_keyUsedIds, defaultValue: 0);
    final nextId = usedIds | (state.loginSession!.gid << _gidShift);
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

  Future<String?> sendRequest(BaseRequest request,
      {bool authRequired = true}) async {
    debugPrint('[api] Sending request to ${request.url}');
    if (authRequired) {
      request.headers.addAll(generateAuthHeaders());
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
    LoginSession<U>? parsedSession;
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
            _metadataKeyLastSyncTime, data[_dataKeyTime] as int?);
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

  ApiAction<D, U, T> _deserializeAction(Map<dynamic, dynamic> actionMap) {
    final name = actionMap[_keyActionName];
    assert(deserializers.containsKey(name));
    final props = actionMap[_keyActionProps] as Map;
    final data = actionMap[_keyActionData];
    final action = deserializers[name]!(props.cast<String, dynamic>(), data);
    return action;
  }

  Future<void> enqueueOfflineAction(ApiAction<D, U, T> action) async {
    while (!state.ready) {
      await stream.firstWhere((state) => state.ready);
    }

    if (!isSignedIn) {
      return;
    }

    await action.applyOptimisticUpdate(this as T);
    debugPrint(
        '[api] Request enqueued: ${action.generateDescription(this as T)}');
    await _actions.add({
      _keyActionName: action.name,
      _keyActionProps: action.toMap(),
      _keyActionData: action.binaryData,
    });
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithActions(
        _actions.values.map<ApiAction<D, U, T>>(
            (actionMap) => _deserializeAction(actionMap)),
      ),
    ));
  }

  Future<void> enqueue(ApiRequest request) async {
    throw Exception('Enqueued deprecated request: $request');
  }

  Future<void> deleteRequestAt(int index, {bool revert = true}) async {
    while (!state.ready) {
      await stream.firstWhere((state) => state.ready);
    }

    if (!isSignedIn ||
        index >= _actions.length ||
        (index == 0 && state.actionQueueState.submitting)) {
      return;
    }

    final action = _deserializeAction(_actions.getAt(index)!);
    await _actions.deleteAt(index);
    if (revert) {
      await action.revertOptimisticUpdate(this as T);
    }

    if (kDebugMode) {
      debugPrint(
          '[api] Deleting request: ${action.generateDescription(this as T)}');
    }
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithActions(
        _actions.values.map((actionMap) => _deserializeAction(actionMap)),
        resetError: index == 0,
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
      await stream.firstWhere((state) => state.ready);
    }

    if (!isSignedIn ||
        _actions.isEmpty ||
        (state.actionQueueState.error?.isNotEmpty ?? false) ||
        state.actionQueueState.paused ||
        state.actionQueueState.submitting) {
      return;
    }

    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithSubmitting(true, null),
    ));

    final action = _deserializeAction(_actions.getAt(0)!);
    final request = action.createRequest(this as T);

    final error = await sendRequest(request);
    emit(state.copyWith(
      actionQueueState: state.actionQueueState.copyWithSubmitting(
        false,
        error,
      ),
    ));
    if (error == null) {
      deleteRequestAt(0, revert: false);
    }
  }

  void fetchUpdates({bool incremental = true}) async {
    debugPrint('[api] Fetching Updates');

    // * Make sure we are ready
    while (!state.ready) {
      await stream.firstWhere((state) => state.ready);
    }
    if (!isSignedIn ||
        state.fetchState.fetching ||
        state.fetchState.connected) {
      return;
    }

    emit(state.copyWith(
      fetchState: const FetchState(fetching: true),
    ));

    final uriBuilder = createUriBuilder('/v1/sync');
    uriBuilder.queryParameters
        .addAll(createLastSyncParams(incremental: incremental));
    final httpRequest = Request('get', uriBuilder.build());

    final error = await sendRequest(httpRequest, authRequired: true);
    emit(state.copyWith(
      fetchState: FetchState(
        fetching: false,
        error: error,
      ),
    ));
  }

  void establishTickerSocket({bool incremental = true}) async {
    // * Make sure we are ready
    while (!state.ready) {
      await stream.firstWhere((state) => state.ready);
    }
    if (tickerPath == null || !isSignedIn || state.fetchState.connected) {
      return;
    }

    final uriBuilder = createUriBuilder(tickerPath!);
    uriBuilder.scheme = uriBuilder.scheme == "https" ? "wss" : "ws";
    uriBuilder.queryParameters
        .addAll(createLastSyncParams(incremental: incremental));

    emit(state.copyWith(
      fetchState: const FetchState(connected: true),
    ));
    // ignore: close_sinks
    _socketFuture = WebSocket.connect(
      uriBuilder.toString(),
      headers: generateAuthHeaders(),
    );
    _socketFuture!.then((socket) {
      debugPrint('[api] Ticker socket created');
      return socket.listen((message) {
        parseResponseString(message);
      }, onError: (err) {
        debugPrint("[api] Ticker socket error: $err");
        _socketFuture = null;
        emit(state.copyWith(
          fetchState: const FetchState(connected: false),
        ));
      }, onDone: () {
        debugPrint(
            '[api] Ticker socket closed: ${socket.closeCode}, ${socket.closeReason}');
        _socketFuture = null;
        emit(state.copyWith(
          fetchState: const FetchState(connected: false),
        ));
        if (socket.closeCode != 1001) {
          // TODO: Exponential backoff
          Future.delayed(Duration(seconds: 1), () {
            establishTickerSocket();
          });
        }
      });
    }, onError: (err) {
      debugPrint("[api] Ticker socket error: $err");
      _socketFuture = null;
      emit(state.copyWith(
        fetchState: const FetchState(connected: false),
      ));
    });
  }

  void closeTickerSocket(String reason) {
    //TODO: test timeout behavior
    _socketFuture
        ?.timeout(Duration.zero)
        .then((socket) => socket.close(1001, reason));
  }
}
