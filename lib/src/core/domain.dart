import 'dart:async';

import 'package:appcore/appcore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'action_queue.dart';
import 'api_client.dart';
import 'domain_hooks.dart';

class Domain<R> {
  final String id;
  final ApiActionQueue<R> actionQueue = ApiActionQueue();
  final ApiClient<R> api;
  late final Box _metadataBox;
  final _ongoingOperations = ValueNotifier<int>(0);
  final List<DomainHooks<R>> _hooks = [];

  bool _closed = false;

  Domain({
    required this.id,
    required this.api,
  });

  @nonVirtual
  Future<void> initialize() async {
    _metadataBox = await Hive.openBox(id);
    await registerHooks(api);
    await registerHooks(actionQueue);
  }

  @nonVirtual
  FutureOr<void> registerHooks(DomainHooks<R> hooks) {
    if (_closed) return null;
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

    await _metadataBox.clear();
    await _metadataBox.close();
    await _metadataBox.deleteFromDisk();
  }

  Future<void> addAction(ApiAction action) async {
    return actionQueue.addAction(action);
  }

  E? getMetadata<E>(String key, {E? defaultValue}) {
    return _metadataBox.get(key) ?? defaultValue;
  }

  void putMetadata<E>(String key, E value) {
    _metadataBox.put(key, value);
  }

  Stream<BoxEvent> watchMetadata({dynamic key}) {
    return _metadataBox.watch(key: key);
  }
}
