import 'dart:async';
import 'dart:io';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/requests/requests.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

const _boxNameApiMetadata = 'apiMetadata';
const _boxNameRequestQueue = 'requestQueue';

const _metadataKeyActionsPaused = 'actionsPaused';

class OfflineCubitState {
  final bool ready;
  final bool fetchingUpdates;
  final bool socketConnected;
  final bool actionsPaused;
  final bool actionSubmitting;
  final bool serverUnreachable;
  final Iterable<ApiRequest> actions;
  final String fetchError;
  final String actionError;

  OfflineCubitState({
    this.ready = false,
    this.fetchingUpdates = false,
    this.socketConnected = false,
    this.actionsPaused = false,
    this.actionSubmitting = false,
    this.serverUnreachable = false,
    this.actions,
    this.fetchError,
    this.actionError,
  });

  OfflineCubitState copyWith({
    bool ready,
    bool fetchingUpdates,
    bool socketConnected,
    bool actionsPaused,
    bool actionSubmitting,
    bool serverUnreachable,
    Iterable<ApiRequest> actions,
    String fetchError,
    String actionError,
  }) {
    return OfflineCubitState(
      ready: ready ?? this.ready,
      fetchingUpdates: fetchingUpdates ?? this.fetchingUpdates,
      socketConnected: socketConnected ?? this.socketConnected,
      actionsPaused: actionsPaused ?? this.actionsPaused,
      actionSubmitting: actionSubmitting ?? this.actionSubmitting,
      serverUnreachable: serverUnreachable ?? this.serverUnreachable,
      actions: actions ?? this.actions,
      fetchError: fetchError ?? this.fetchError,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
  
    return o is OfflineCubitState &&
      o.ready == ready &&
      o.fetchingUpdates == fetchingUpdates &&
      o.socketConnected == socketConnected &&
      o.actionsPaused == actionsPaused &&
      o.actionSubmitting == actionSubmitting &&
      o.serverUnreachable == serverUnreachable &&
      o.actions == actions &&
      o.fetchError == fetchError &&
      o.actionError == actionError;
  }

  @override
  int get hashCode {
    return ready.hashCode ^
      fetchingUpdates.hashCode ^
      socketConnected.hashCode ^
      actionsPaused.hashCode ^
      actionSubmitting.hashCode ^
      serverUnreachable.hashCode ^
      actions.hashCode ^
      fetchError.hashCode ^
      actionError.hashCode;
  }

  String get status {
    if (!ready) {
      return "Initializing";
    }
    if (actionSubmitting) {
      return "Submitting";
    }
    if (actionsPaused) {
      return "Paused";
    }
    if (serverUnreachable) {
      return "Server Unreachable";
    }
    if (actionError != null) {
      return "Error";
    }
    return "Ready";
  }
}

class OfflineCubit extends Cubit<OfflineCubitState> {
  final ApiCubit apiCubit;
  Future<WebSocket> socketFuture;
  Box _metadata;
  Box<ApiRequest> _requests;

  OfflineCubit(this.apiCubit) : super(OfflineCubitState()) {
    debugPrint('[api] Initializing');
    Hive.registerAdapter(UploadApiRequestAdapter());
    Hive.registerAdapter(SimpleApiRequestAdapter());

    _initialize();
  }

  Future<void> _initialize() async {
    _requests = await Hive.openBox(_boxNameRequestQueue);
    _metadata = await Hive.openBox(_boxNameApiMetadata);

    emit(OfflineCubitState(
      ready: true,
      actionsPaused:
          _metadata.get(_metadataKeyActionsPaused, defaultValue: false),
      actions: _requests.values,
    ));
    debugPrint('[api] Ready');
    sendNextRequest();
  }

  Future<void> clear() async {
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

    await Hive.deleteBoxFromDisk(_boxNameRequestQueue);
    await Hive.deleteBoxFromDisk(_boxNameApiMetadata);
    await _initialize();
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

  void pause({bool persistent = false}) {
    debugPrint('[api] Pausing');
    if (persistent) _metadata.put(_metadataKeyActionsPaused, true);
    emit(state.copyWith(actionsPaused: true));
  }

  void resume() {
    debugPrint('[api] Resuming');
    _metadata.put(_metadataKeyActionsPaused, false);
    emit(state.copyWith(actionsPaused: false));
    sendNextRequest();
  }

  void sendNextRequest() async {
    // * Make sure we are ready
    while (!state.ready) {
      await firstWhere((state) => state.ready);
    }

    if (!apiCubit.isSignedIn ||
        _requests.isEmpty ||
        state.actionsPaused ||
        state.actionSubmitting) {
      return;
    }

    emit(state.copyWith(actionSubmitting: true));
    final request = _requests.getAt(0);

    final uriBuilder = apiCubit.createUriBuilder(request.endpoint);
    uriBuilder.queryParameters.addAll(apiCubit.createLastSyncParams());
    final httpRequest = await request.createRequest(uriBuilder.build());

    try {
      final response = await apiCubit.sendAuthenticatedRequest(httpRequest);
      String responseString = await response.stream.bytesToString();

      // Show request result
      if (response.statusCode == 200) {
        await apiCubit.parseResponseString(responseString);
        emit(state.copyWith(actionSubmitting: false, actionError: ''));
        deleteRequest(request);
      } else {
        emit(state.copyWith(
            actionSubmitting: false, actionError: responseString));
      }
    } catch (e) {
      if (e is SocketException) {
        emit(state.copyWith(actionSubmitting: false, serverUnreachable: true));
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
    if (!apiCubit.isSignedIn ||
        state.fetchingUpdates ||
        state.socketConnected) {
      return;
    }

    emit(state.copyWith(fetchingUpdates: true));
    debugPrint('[api-sync] Fetching Updates');

    final uriBuilder = apiCubit.createUriBuilder('/v1/sync');
    uriBuilder.queryParameters
        .addAll(apiCubit.createLastSyncParams(incremental: incremental));
    final httpRequest = Request('get', uriBuilder.build());

    try {
      final response = await apiCubit.sendAuthenticatedRequest(httpRequest);
      String responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        await apiCubit.parseResponseString(responseString);
        emit(state.copyWith(fetchingUpdates: false, fetchError: ''));
      } else {
        emit(
            state.copyWith(fetchingUpdates: false, fetchError: responseString));
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        emit(state.copyWith(fetchingUpdates: false, serverUnreachable: true));
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
    if (!apiCubit.isSignedIn ||
        state.socketConnected) {
      return;
    }

    final uriBuilder = apiCubit.createUriBuilder('/v1/ticker');
    uriBuilder.scheme = uriBuilder.scheme == "https" ? "wss" : "ws";
    uriBuilder.queryParameters
        .addAll(apiCubit.createLastSyncParams(incremental: true));

    // ignore: close_sinks
    socketFuture = WebSocket.connect(
      uriBuilder.toString(),
      headers: {"Authorization": 'SessionId ${apiCubit.state.sessionId}'},
    );
    emit(state.copyWith(socketConnected: true));
    socketFuture.then((socket) {
      debugPrint('[api-sync] Ticker channel created');
      return socket.listen((message) {
        debugPrint("[api-sync] Ticker message");
        apiCubit.parseResponseString(message);
      }, onError: (err) {
        debugPrint("[api-sync] Ticker error: $err");
        socketFuture = null;
        emit(state.copyWith(socketConnected: false));
      }, onDone: () {
        debugPrint(
            '[api-sync] Ticker closed: ${socket.closeCode}, ${socket.closeReason}');
        socketFuture = null;
        emit(state.copyWith(socketConnected: false));
      });
    }, onError: (err) {
      debugPrint("[api-sync] Ticker socket error: $err");
      socketFuture = null;
      emit(state.copyWith(socketConnected: false));
    });
  }
}
