import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:appcore/core/api.dart';
import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:uri/uri.dart';

const _delays = [0, 2, 4, 8, 16, 32, 64];

abstract class TickerSyncCubit extends Cubit<TickerSyncState> {
  final ApiCubit api;

  late final void Function(dynamic) _successfulResponseProcessor = (response) {
    if (state is TickerSyncStateDisconnected) {
      connect();
    }
  };

  CancelableOperation<bool>? _delayOperation;
  CancelableOperation<WebSocket>? _connectOperation;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;

  TickerSyncCubit(
    this.api,
  ) : super(const TickerSyncStateDisconnected(0)) {
    // Logout
    api.stream.listen((apiState) {
      if (apiState.session == null) {
        debugPrint('[sync] Logging Out');
        disconnect('logout');
      } else {
        connect();
      }
    });

    // Exponential backoff
    stream.listen((TickerSyncState state) {
      if (state is TickerSyncStateDisconnected && state.attempt > 0) {
        _connect(state.attempt);
      }
    });

    // Try connecting when a successful response is parsed
    api.addResponseProcessor(_successfulResponseProcessor);

    connect();
  }

  @override
  Future<void> close() async {
    debugPrint('[sync] BLoC close');
    api.removeResponseProcessor(_successfulResponseProcessor);
    disconnect('close');
    await super.close();
  }

  UriBuilder createUriBuilder();

  void connect() async {
    debugPrint('[sync] Connect');
    _connect(0);
  }

  void disconnect(String reason) {
    debugPrint('[sync] Disconnect');
    _delayOperation?.cancel();
    _connectOperation?.cancel();
    _socketSubscription?.cancel();
    _socket?.close(1001, reason);
    emit(const TickerSyncStateDisconnected(-1));
  }

  void _connect(int attempt) async {
    debugPrint('[sync] Connection attempt $attempt');

    _delayOperation?.cancel();
    if (attempt > 0) {
      // Exponential backoff delay
      int delaySeconds = _delays[min(attempt, _delays.length - 1)];
      debugPrint('Waiting for $delaySeconds seconds');
      final delay = CancelableOperation.fromFuture(
          Future.delayed(Duration(seconds: delaySeconds), () => true));
      _delayOperation = delay;
      final delaySuccess = await delay.valueOrCancellation(false) ?? false;
      if (!delaySuccess) {
        debugPrint('Delay canceled: $delaySeconds');
        return;
      }
      _delayOperation = null;
      debugPrint('Delay finished: $delaySeconds');
    }

    if (api.state is! ApiStateLoggedIn ||
        state is! TickerSyncStateDisconnected) {
      return;
    }

    final uriBuilder = createUriBuilder();
    uriBuilder.scheme = uriBuilder.scheme == "https" ? "wss" : "ws";

    debugPrint('[sync] Connecting');
    emit(const TickerSyncStateConnecting());

    final session = api.state.session;
    final operation = CancelableOperation.fromFuture(WebSocket.connect(
      uriBuilder.toString(),
      headers: api.headers,
    ));

    try {
      _connectOperation = operation;
      _socket = await operation.valueOrCancellation();

      _socketSubscription = _socket?.listen((message) {
        api.parseResponseString(message, requestSession: session);
      }, onError: (err) {
        final socket = _socket;
        _socket = null;
        socket?.close(
          1002,
        );
        debugPrint("[sync] Listen error: $err");
        emit(const TickerSyncStateDisconnected(1));
      }, onDone: () {
        // debugPrint('[sync] Closed: ${socket.closeCode}, ${socket.closeReason}');
        emit(TickerSyncStateDisconnected(-1));
      });

      debugPrint('[sync] Connected');
      emit(const TickerSyncStateConnected());
    } catch (err) {
      _socket = null;
      debugPrint("[sync] Connection error: $err");
      emit(TickerSyncStateDisconnected(attempt + 1));
    } finally {
      _connectOperation = null;
    }
  }

  UriBuilder addParams(UriBuilder builder) => builder;
}

abstract class TickerSyncState {
  const TickerSyncState();
}

class TickerSyncStateDisconnected extends TickerSyncState {
  final int attempt;

  const TickerSyncStateDisconnected(this.attempt);
}

class TickerSyncStateConnecting extends TickerSyncState {
  const TickerSyncStateConnecting();
}

class TickerSyncStateConnected extends TickerSyncState {
  const TickerSyncStateConnected();
}
