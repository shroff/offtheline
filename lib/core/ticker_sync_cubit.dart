import 'dart:io';

import 'package:appcore/core/api.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:uri/uri.dart';

abstract class TickerSyncCubit<S extends ApiSession, T extends ApiCubit<S, T>>
    extends Cubit<TickerSyncState> {
  final T api;

  Future<WebSocket>? _socketFuture;

  TickerSyncCubit(
    this.api,
  ) : super(const TickerSyncStateDisconnected()) {
    api.stream.listen((event) {
      if (event.loginSession == null) {
        disconnect('logout');
      } else {
        connect();
      }
    });
  }

  UriBuilder createUriBuilder();

  void connect() async {
    // * Make sure we are ready
    while (!api.state.ready) {
      await api.stream.firstWhere((state) => state.ready);
    }
    if (!api.isSignedIn || state is! TickerSyncStateDisconnected) {
      return;
    }

    final uriBuilder = createUriBuilder();
    uriBuilder.scheme = uriBuilder.scheme == "https" ? "wss" : "ws";

    debugPrint('[sync] Connecting');
    emit(const TickerSyncStateConnecting());

    // ignore: close_sinks
    _socketFuture = WebSocket.connect(
      uriBuilder.toString(),
      headers: api.headers,
    );
    _socketFuture!.then((socket) {
      debugPrint('[sync] Connected');
      emit(const TickerSyncStateConnected());

      return socket.listen((message) {
        api.parseResponseString(message);
      }, onError: (err) {
        _socketFuture = null;
        debugPrint("[sync] Listen error: $err");
        emit(const TickerSyncStateDisconnected());
      }, onDone: () {
        _socketFuture = null;
        debugPrint('[sync] Closed: ${socket.closeCode}, ${socket.closeReason}');
        emit(const TickerSyncStateDisconnected());
        if (socket.closeCode != 1001) {
          // TODO: Exponential backoff
          Future.delayed(Duration(seconds: 1), () {
            connect();
          });
        }
      });
    }, onError: (err) {
      debugPrint("[api] Ticker socket connection error: $err");
      _socketFuture = null;
      emit(TickerSyncStateDisconnected());
    });
  }

  UriBuilder addParams(UriBuilder builder) => builder;

  void disconnect(String reason) {
    //TODO: test timeout behavior
    _socketFuture
        ?.timeout(Duration.zero)
        .then((socket) => socket.close(1001, reason));
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
  const TickerSyncStateConnected();
}
