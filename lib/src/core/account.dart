import 'dart:async';

import 'package:meta/meta.dart';
import 'package:offtheline/src/core/persistence.dart';
import 'package:state_notifier/state_notifier.dart';

import 'action_queue.dart';
import '../actions/api_action.dart';
import 'api_client.dart';
import 'account_listener.dart';
import 'global.dart';

class Account<Datastore> {
  final String id;
  final ApiActionQueue<Datastore> actionQueue = ApiActionQueue();
  final Datastore datastore;
  final ApiClient<Datastore> api;
  final AccountPersistence persistence;
  final _ongoingOperations = _Counter();
  final List<AccountListener<Datastore>> _listeners = [];

  final _boxOpenedCompleter = Completer();
  final _initializationCompleter = Completer();
  Future get initialized => _initializationCompleter.future;

  bool _closed = false;

  Account({
    required this.id,
    required this.datastore,
    required this.api,
    bool clear = false,
  }) : persistence = AccountPersistence(id: id, clear: clear) {
    persistence.initialized.then((value) async {
      await registerListener(api);
      await registerListener(actionQueue);
      await initialize();
      _initializationCompleter.complete();
    });
  }

  @protected
  @mustCallSuper
  Future<void> initialize() async {}

  @nonVirtual
  FutureOr<void> registerListener(AccountListener<Datastore> listener) async {
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

    await persistence.delete();
  }

  Future<void> addAction(ApiAction<Datastore> action) async {
    return actionQueue.addAction(action);
  }
}

class _Counter extends StateNotifier<int> {
  _Counter() : super(0);

  int get value => state;

  void increment() => state = state + 1;

  void decrement() => state = state - 1;
}
