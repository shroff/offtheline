import 'dart:async';
import 'dart:isolate';

import 'package:flutter/rendering.dart';

import 'item_processor.dart';

Future<Map<K, R>> processItems<K, T, R>(
  SingleItemProcessor<T, R> processItem,
  bool useIsolateIfAvailable,
  Map<K, T> items,
) async {
  final ReceivePort receivePort = ReceivePort();
  final isolateEntryData = _IsolateEntryData(receivePort.sendPort, processItem);
  final isolate = (useIsolateIfAvailable)
      ? await Isolate.spawn(_GenericIsolateEntry.entry,
          _GenericIsolateEntry<K, T, R>(_processImagesIsolateEntry, isolateEntryData))
      : null;
  if (useIsolateIfAvailable) {
    debugPrint('Using Isolate');
  } else {
    _processImagesIsolateEntry<K, T, R>(isolateEntryData);
  }

  final completer = Completer<Map<K, R>>();
  final result = <K, R>{};

  receivePort.listen((msg) {
    if (msg is SendPort) {
      final sendPort = msg;
      for (final entry in items.entries) {
        debugPrint('Sending ${entry.key} for processing');
        sendPort.send(_KVPair(entry.key, entry.value));
      }
      sendPort.send(null);
    } else if (msg is _KVPair<K, R>) {
      result[msg.key] = msg.value;
      debugPrint('Received result for ${msg.key}');
    } else if (msg == null) {
      debugPrint('All items processed. Killing Isolate');
      receivePort.close();
      isolate?.kill();
      completer.complete(result);
    } else if (msg is Exception) {
      debugPrint('Exception caught. Killing Isolate');
      debugPrint(msg.toString());
      receivePort.close();
      isolate?.kill();
      completer.completeError(msg);
    } else {
      debugPrint('Unknown message received. Killing Isolate');
      receivePort.close();
      isolate?.kill();
      completer.completeError('Unknown message: $msg');
    }
  });
  return completer.future;
}

void _processImagesIsolateEntry<K, T, R>(_IsolateEntryData<T, R> data) async {
  final sendPort = data.port;
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  int pending = 0;
  bool open = true;
  receivePort.listen(
    (msg) async {
      if (msg == null) {
        debugPrint('Finished receiving items. Closing receive port');
        open = false;
        receivePort.close();
      } else if (msg is _KVPair<K, T>) {
        debugPrint('Processing ${msg.key}');
        pending++;
        try {
          final result = await data.processItem(msg.value);
          sendPort.send(_KVPair(msg.key, result));
        } on Exception catch (e) {
          receivePort.close();
          sendPort.send(e);
        }
        pending--;
      }

      if (!open && pending == 0) {
        sendPort.send(null);
      }
    },
  );
}

class _KVPair<K, T> {
  final K key;
  final T value;

  _KVPair(this.key, this.value);
}

class _IsolateEntryData<T, R> {
  final SendPort port;
  final SingleItemProcessor<T, R> processItem;

  _IsolateEntryData(this.port, this.processItem);
}

class _GenericIsolateEntry<K, T, R> {
  final _IsolateEntryData<T, R> parameter;
  final void Function<K, T, R>(_IsolateEntryData<T, R>) function;

  _GenericIsolateEntry(this.function, this.parameter);

  void call() {
    function<K, T, R>(parameter);
  }

  static void entry(_GenericIsolateEntry parameters) {
    parameters();
  }
}
