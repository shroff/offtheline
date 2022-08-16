import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import 'action_queue.dart';
import '../actions/api_action.dart';
import 'api_client.dart';
import 'account_hooks.dart';
import 'global.dart';

class Account<R> {
  final String id;
  final ApiActionQueue<R> actionQueue = ApiActionQueue();
  final ApiClient<R> api;
  final List<Box> openBoxes = [];
  late final Box _persist;
  final bool clear;
  final _ongoingOperations = _Counter();
  final List<AccountHooks<R>> _hooks = [];

  final _boxOpenedCompleter = Completer();
  final _initializationCompleter = Completer();
  Future get initialized => _initializationCompleter.future;

  bool _closed = false;

  Account({
    required this.id,
    required this.api,
    this.clear = false,
  }) {
    openBox('persist').then((box) async {
      if (clear) {
        OTL.logger
            ?.i('[account][$id] Clearing ${box.values.length} stale entries');
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
  FutureOr<void> registerHooks(AccountHooks<R> hooks) async {
    if (_closed) return null;
    await _boxOpenedCompleter.future;
    _hooks.add(hooks);
    return hooks.initialize(this);
  }

  @nonVirtual
  void registerOngoingOperation(Future future) {
    if (_closed) return;
    _ongoingOperations.increment();
    future.then(
      (value) => _ongoingOperations.decrement(),
      onError: (err) => _ongoingOperations.decrement(),
    );
  }

  @nonVirtual
  Future<void> delete() async {
    if (_closed) return;
    _closed = true;

    OTL.logger?.i('[account][$id] Logging Out');

    for (final hooks in _hooks) {
      await hooks.close();
    }

    // Wait for pending operations
    final completer = Completer();
    final removeListener = _ongoingOperations.addListener((value) {
      if (value == 0) {
        completer.complete();
      }
    }, fireImmediately: true);
    await completer.future;
    removeListener();

    for (final box in openBoxes) {
      await box.close();
      await Hive.deleteBoxFromDisk(box.name);
    }
  }

  Future<void> addAction(ApiAction<Account<R>> action) async {
    return actionQueue.addAction(action);
  }

  E? getPersisted<E>(String key) {
    return _persist.get(key);
  }

  Future<void> persist<E>(String key, E value) {
    if (value == null) {
      return _persist.delete(key).then((value) => _persist.flush());
    } else {
      return _persist.put(key, value).then((value) => _persist.flush());
    }
  }

  Future<Box<T>> openBox<T>(String name) async {
    final box = await Hive.openBox<T>('$id-$name');
    if (clear) {
      await box.clear();
    }
    openBoxes.add(box);
    return box;
  }

  Stream<BoxEvent> watchMetadata({dynamic key}) {
    return _persist.watch(key: key);
  }
}

class _Counter extends StateNotifier<int> {
  _Counter() : super(0);

  int get value => state;

  void increment() => state = state + 1;

  void decrement() => state = state - 1;
}
