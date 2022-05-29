import 'dart:async';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:uri/uri.dart';

const _delays = [5, 10, 15, 30, 60, 120];

abstract class TickerSyncCubit extends ChangeNotifier {
  final ApiClient api;
  TickerSyncState _state = TickerSyncStateDisconnected();

  late final void Function(dynamic, dynamic) _successfulResponseProcessor =
      (response, tag) {
    if (_state is TickerSyncStateDisconnected) {
      connect();
    }
  };

  CancellableDelay? _delayOperation;

  TickerSyncCubit(
    this.api,
  ) {
    // Try connecting when a successful response is parsed
    api.addResponseProcessor(_successfulResponseProcessor);

    connect();
  }

  @override
  void dispose() async {
    super.dispose();
    api.removeResponseProcessor(_successfulResponseProcessor);
    disconnect('close');
  }

  UriBuilder createUriBuilder();

  void connect() async {
    debugPrint('[sync] Connect');
    _connect(0);
  }

  void disconnect(String reason) {
    debugPrint('[sync] Disconnect');
    _delayOperation?.cancel();

    final state = _state;
    if (state is TickerSyncStateConnected) {
      state.channel.sink.close(1001, reason);
    }
    _state = TickerSyncStateDisconnected();
  }

  void _connect(int attempt) async {
    debugPrint('[sync] Connection attempt $attempt');

    _delayOperation?.cancel();
    if (attempt > 0) {
      // Exponential backoff delay
      int delaySeconds = _delays[min(attempt - 1, _delays.length - 1)];
      debugPrint('[sync] Waiting for $delaySeconds seconds');
      final delay = CancellableDelay(Duration(seconds: delaySeconds));
      _delayOperation = delay;
      final delaySuccess = await delay.wait();
      if (!delaySuccess) {
        debugPrint('Delay canceled: $delaySeconds');
        return;
      }
      _delayOperation = null;
      debugPrint('Delay finished: $delaySeconds');
    }

    if (_state is! TickerSyncStateDisconnected) {
      return;
    }

    final uriBuilder = createUriBuilder();
    uriBuilder.scheme = uriBuilder.scheme == "https" ? "wss" : "ws";

    debugPrint('[sync] Connecting');
    _state = TickerSyncStateConnecting();

    final channel = WebSocketChannel.connect(uriBuilder.build());
    initiateConnection(channel.sink);

    channel.stream.listen(
      (message) {
        if (_state is! TickerSyncStateConnected) {
          debugPrint('[sync] Connected');
          _state = TickerSyncStateConnected(channel);
          attempt = 0;
        }
        processResponseString(message);
      },
      // Auto-reconnect with exponential backoff
      onDone: () {
        debugPrint('[sync] Stream Done');
        _state = TickerSyncStateDisconnected();
        _connect(attempt + 1);
      },
      onError: (err) {
        debugPrint('[sync] Stream Error');
        _state = TickerSyncStateDisconnected();
        _connect(attempt + 1);
      },
      cancelOnError: true,
    );
  }

  @protected
  void initiateConnection(Sink sink) {}

  @protected
  void processResponseString(String response) {
    api.processResponseString(response);
  }
}

abstract class TickerSyncState {
  const TickerSyncState();
}

class TickerSyncStateDisconnected extends TickerSyncState {
  const TickerSyncStateDisconnected();
}

class TickerSyncStateConnecting extends TickerSyncState {
  const TickerSyncStateConnecting();
}

class TickerSyncStateConnected extends TickerSyncState {
  final WebSocketChannel channel;
  const TickerSyncStateConnected(this.channel);
}

class CancellableDelay {
  final Completer<bool> _completer = Completer();

  CancellableDelay(Duration duration) {
    Future.delayed(duration, () {
      if (!_completer.isCompleted) {
        _completer.complete(true);
      }
    });
  }

  Future<bool> wait() {
    return _completer.future;
  }

  void cancel() {
    _completer.complete(false);
  }
}
