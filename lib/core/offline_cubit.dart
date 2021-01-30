import 'dart:async';
import 'dart:io';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/requests/requests.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uri/uri.dart';

const _boxNameApiMetadata = 'apiMetadata';
const _boxNameRequestQueue = 'requestQueue';

const _metadataKeyPaused = 'paused';

class OfflineCubitState {
  final bool ready;
  final bool paused;
  final bool submitting;
  final bool serverUnreachable;
  final Iterable<ApiRequest> requests;
  final String lastRequestError;

  OfflineCubitState({
    this.ready = false,
    this.paused = false,
    this.submitting = false,
    this.serverUnreachable = false,
    this.requests,
    this.lastRequestError,
  });

  OfflineCubitState copyWith({
    bool ready,
    bool paused,
    bool submitting,
    bool serverUnreachable,
    Iterable<ApiRequest> requests,
    String lastRequestError,
  }) {
    return OfflineCubitState(
      ready: ready ?? this.ready,
      paused: paused ?? this.paused,
      submitting: submitting ?? this.submitting,
      serverUnreachable: serverUnreachable ?? this.serverUnreachable,
      requests: requests ?? this.requests,
      lastRequestError: lastRequestError ?? this.lastRequestError,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is OfflineCubitState &&
        o.ready == ready &&
        o.paused == paused &&
        o.submitting == submitting &&
        o.serverUnreachable == serverUnreachable &&
        o.requests == requests &&
        o.lastRequestError == lastRequestError;
  }

  @override
  int get hashCode {
    return ready.hashCode ^
        paused.hashCode ^
        submitting.hashCode ^
        serverUnreachable.hashCode ^
        requests.hashCode ^
        lastRequestError.hashCode;
  }

  String get status {
    if (!ready) {
      return "Initializing";
    }
    if (submitting) {
      return "Submitting";
    }
    if (paused) {
      return "Paused";
    }
    if (serverUnreachable) {
      return "Server Unreachable";
    }
    if (lastRequestError != null) {
      return "Error";
    }
    return "Ready";
  }
}

class OfflineCubit extends Cubit<OfflineCubitState> {
  final ApiCubit apiCubit;
  Box _metadata;
  Box<ApiRequest> _requests;

  OfflineCubit(this.apiCubit) : super(OfflineCubitState()) {
    initialize();
  }

  Future<void> initialize() async {
    debugPrint('[api] Initializing');
    Hive.registerAdapter(UploadApiRequestAdapter());
    Hive.registerAdapter(SimpleApiRequestAdapter());

    bool paused = _metadata.get(_metadataKeyPaused, defaultValue: false);
    await _openBoxesAndStart(paused: paused);
  }

  Future<void> clear() async {
    debugPrint('[api] Clearing');
    // * Wait for any syncing request to finish
    if (state.submitting) {
      await firstWhere((state) => !state.submitting);
    }

    emit(OfflineCubitState());
    await Hive.deleteBoxFromDisk(_boxNameRequestQueue);
    await Hive.deleteBoxFromDisk(_boxNameApiMetadata);
    await _openBoxesAndStart();
  }

  Future<void> _openBoxesAndStart({bool paused = false}) async {
    _requests = await Hive.openBox(_boxNameRequestQueue);
    _metadata = await Hive.openBox(_boxNameApiMetadata);

    emit(OfflineCubitState(
      ready: true,
      paused: paused,
      requests: _requests.values,
    ));
    debugPrint('[api] Ready');
    sendNextRequest();
  }

  Future<void> enqueue(ApiRequest request) async {
    debugPrint(
        '[api] Request enqueued: ${request.endpoint} | ${request.description}');
    await _requests.add(request);
    emit(state.copyWith(requests: _requests.values));
    sendNextRequest();
  }

  Future<void> deleteRequestAt(int index) async {
    if (index >= _requests.length) return;
    if (kDebugMode) {
      final request = _requests.getAt(index);
      debugPrint(
          '[api] Deleting request: ${request.endpoint} | ${request.description}');
    }
    await _requests.deleteAt(index);
    emit(state.copyWith(requests: _requests.values));
    sendNextRequest();
  }

  Future<void> deleteRequest(ApiRequest request) async {
    bool isFirstRequest = request == _requests.getAt(0);
    if (isFirstRequest && state.submitting) {
      return;
    }
    await request.delete();
    var nextState = state.copyWith(
      requests: _requests.values,
      lastRequestError: isFirstRequest ? '' : null,
    );
    emit(nextState);
    sendNextRequest();
  }

  void pause({bool persistent = false}) {
    debugPrint('[api] Pausing');
    if (persistent) _metadata.put(_metadataKeyPaused, true);
    emit(state.copyWith(paused: true));
  }

  void resume() {
    debugPrint('[api] Resuming');
    _metadata.put(_metadataKeyPaused, false);
    emit(state.copyWith(paused: false));
    sendNextRequest();
  }

  void sendNextRequest() async {
    // * Make sure we are ready
    if (!state.ready) {
      await firstWhere((state) => state.ready);
    }

    if (!apiCubit.isSignedIn ||
        _requests.isEmpty ||
        state.paused ||
        state.submitting) {
      emit(state.copyWith(submitting: false));
      return;
    }
    emit(state.copyWith(submitting: true));
    final request = _requests.getAt(0);

    final queryParams = apiCubit.createLastSyncParams();
    final uriBuilder =
        UriBuilder.fromUri(Uri.parse(apiCubit.createUrl(request.endpoint)));
    uriBuilder.queryParameters.addAll(queryParams);

    try {
      final httpRequest = await request.createRequest(uriBuilder.build());
      final response = await apiCubit.sendAuthenticatedRequest(httpRequest);

      // Show request result
      if (response.statusCode == 200) {
        await apiCubit
            .parseResponseString(await response.stream.bytesToString());
        emit(state.copyWith(submitting: false, lastRequestError: ''));
        deleteRequest(request);
      } else {
        final details = await response.stream.bytesToString();
        emit(state.copyWith(submitting: false, lastRequestError: details));
      }
    } catch (e) {
      if (e is SocketException) {
        emit(state.copyWith(submitting: false, serverUnreachable: true));
      } else {
        emit(state.copyWith(submitting: false, lastRequestError: e.toString()));
      }
    }
  }
}
