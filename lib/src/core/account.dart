import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import 'action_queue.dart';
import '../actions/api_action.dart';
import 'api_client.dart';
import 'account_listener.dart';
import 'global.dart';

const _boxNamePersist = 'persist';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
const _accountIdLength = 16;
final _random = Random();

class Account<R> {
  final String id;
  final ApiActionQueue<R> actionQueue = ApiActionQueue();
  final ApiClient<R> api;
  late final Box _persist;
  final _ongoingOperations = _Counter();
  final List<AccountListener<R>> _listeners = [];

  final _boxOpenedCompleter = Completer();
  final _initializationCompleter = Completer();
  Future get initialized => _initializationCompleter.future;

  bool _closed = false;

  Account({
    String? id,
    required this.api,
  }) : id = id ?? generateRandomId() {
    openBox(_boxNamePersist).then((box) async {
      _persist = box;
      _boxOpenedCompleter.complete();
      await registerListener(api);
      await registerListener(actionQueue);
      await initialize();
      _initializationCompleter.complete();
    });
  }

  static String generateRandomId() {
    return String.fromCharCodes(Iterable.generate(_accountIdLength,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
  }

  @protected
  @mustCallSuper
  Future<void> initialize() async {}

  @nonVirtual
  FutureOr<void> registerListener(AccountListener<R> listener) async {
    if (_closed) return null;
    await _boxOpenedCompleter.future;
    _listeners.add(listener);
    return listener.initialize(this);
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

    for (final listeners in _listeners) {
      await listeners.delete();
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

    _persist.deleteFromDisk();
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

  Future<Box<T>> openBox<T>(String name) {
    return Hive.openBox<T>('$id-$name');
  }

  Future deleteBox(String name) {
    return Hive.deleteBoxFromDisk('$id-$name');
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
