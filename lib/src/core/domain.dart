import 'dart:async';

import 'package:appcore/appcore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class Domain<R> {
  final String id;
  final ApiActionQueue<R> actionQueue = ApiActionQueue();
  final ApiClient<R> api;
  late final Box _persist;
  final _ongoingOperations = ValueNotifier<int>(0);
  final List<DomainHooks<R>> _hooks = [];

  final _boxOpenedCompleter = Completer();
  final _initializationCompleter = Completer();
  Future get initialized => _initializationCompleter.future;

  bool _closed = false;

  Domain({
    required this.id,
    required this.api,
    bool clear = false,
  }) {
    Hive.openBox(id).then((box) async {
      if (clear) {
        debugPrint('[api] Clearing ${box.values.length} stale entries');
        await box.clear();
      }
      _persist = box;
      _boxOpenedCompleter.complete();
      await registerHooks(api);
      await registerHooks(actionQueue);
      await initialize();
      _initializationCompleter.complete();
    });
  }

  @protected
  @mustCallSuper
  Future<void> initialize() async {}

  @nonVirtual
  FutureOr<void> registerHooks(DomainHooks<R> hooks) async {
    if (_closed) return null;
    await _boxOpenedCompleter.future;
    _hooks.add(hooks);
    return hooks.initialize(this);
  }

  @nonVirtual
  void registerOngoingOperation(Future future) {
    if (_closed) return;
    _ongoingOperations.value = _ongoingOperations.value + 1;
    future.then(
      (value) => _ongoingOperations.value = _ongoingOperations.value - 1,
      onError: (err) => _ongoingOperations.value = _ongoingOperations.value - 1,
    );
  }

  @nonVirtual
  Future<void> delete() async {
    if (_closed) return;
    _closed = true;

    debugPrint('[api] Logging Out');

    _hooks.forEach((hooks) {
      hooks.close();
    });

    // Wait for pending operations
    if (_ongoingOperations.value != 0) {
      final completer = Completer();
      final callback = () {
        if (_ongoingOperations.value == 0) {
          completer.complete();
        }
      };
      _ongoingOperations.addListener(callback);
      await completer.future;
      _ongoingOperations.removeListener(callback);
    }

    await _persist.deleteFromDisk();
  }

  Future<void> addAction(ApiAction action) async {
    return actionQueue.addAction(action);
  }

  E? getPersisted<E>(String key) {
    return _persist.get(key);
  }

  Future<void> persist<E>(String key, E value) {
    if (value == null) {
      return _persist.delete(key);
    } else {
      return _persist.put(key, value);
    }
  }

  Stream<BoxEvent> watchMetadata({dynamic key}) {
    return _persist.watch(key: key);
  }
}
