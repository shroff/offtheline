import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

import 'package:appcore/core/api_cubit.dart';

@immutable
class ApiSyncState {
  final bool fetchingUpdates;
  final bool socketConnected;

  ApiSyncState({
    this.fetchingUpdates = false,
    this.socketConnected,
  });

  ApiSyncState copyWith({
    bool fetchingUpdates,
    bool socketConnected,
  }) {
    return ApiSyncState(
      fetchingUpdates: fetchingUpdates ?? this.fetchingUpdates,
      socketConnected: socketConnected ?? this.socketConnected,
    );
  }
}

class ApiSyncCubit extends Cubit<ApiSyncState> {
  Future<WebSocket> socketFuture;

  ApiSyncCubit() : super(ApiSyncState());

  void establishTickerSocket(BuildContext context) async {
    final apiCubit = context.read<ApiCubit>();

    if (!apiCubit.isSignedIn) {
      return;
    }

    if (socketFuture != null) {
      return;
    }

    final baseUri = Uri.parse(apiCubit.createUrl('/v1/ticker'));
    final uriBuilder = UriBuilder.fromUri(baseUri)
      ..scheme = baseUri.scheme == "https" ? "wss" : "ws";
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

  void fetchUpdates(BuildContext context, {bool incremental = true}) async {
    if (state.fetchingUpdates || state.socketConnected) return;

    final apiCubit = context.read<ApiCubit>();

    if (!apiCubit.isSignedIn) {
      _setLoadingError("Not Signed In");
      return;
    }

    _setLoading(true);
    debugPrint('[api-sync] Fetching Updates');

    final uriBuilder =
        UriBuilder.fromUri(Uri.parse(apiCubit.createUrl('/v1/sync')));
    uriBuilder.queryParameters.addAll(
        apiCubit.createLastSyncParams(incremental: incremental));
    final httpRequest = Request('get', uriBuilder.build());

    try {
      final response = await apiCubit.sendAuthenticatedRequest(httpRequest);

      if (response.statusCode == 200) {
        await apiCubit.parseResponseString(await response.stream.bytesToString());
        _setLoading(false);
      } else {
        String responseString = await response.stream.bytesToString();
        debugPrint('Loading Error: $responseString');
        _setLoadingError(responseString);
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        _setLoadingError('Server Unreachable');
      } else {
        _setLoadingError(e.toString());
      }
    }
  }

  void _setLoadingError(String errorMessage) {
    addError(errorMessage);
  }

  void _setLoading(bool loading) {
    emit(state.copyWith(fetchingUpdates: loading));
  }
}
