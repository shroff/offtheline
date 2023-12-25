import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import '../actions/api_action.dart';
import 'api_error_response.dart';
import 'account.dart';
import 'account_listener.dart';
import 'global.dart';

const _actionsBoxName = 'actions';

class ApiActionQueueState {
  final List<ApiAction> actions;
  final bool paused;
  final bool submitting;
  final ApiErrorResponse? error;

  ApiActionQueueState(this.actions, this.paused, this.submitting, this.error);
}

class ApiActionQueue<R> extends StateNotifier<ApiActionQueueState> with AccountListener<R>, LocatorMixin {
  late final Box<ApiAction<Account<R>>> _actionsBox;
  late final Function() _removeListener;
  Iterable<ApiAction> get actions => List.unmodifiable(state.actions);

  bool get paused => state.paused;

  bool get submitting => state.submitting;

  ApiErrorResponse? get error => state.error;

  ApiActionQueue() : super(ApiActionQueueState([], false, false, null));

  @protected
  @override
  Future<void> initialize(Account<R> account) async {
    OTL.logger?.d('[actions][${account.id}] Initializing');
    super.initialize(account);

    _actionsBox = await account.openBox(_actionsBoxName);
    final actions = _actionsBox.values.toList()..sort((a, b) => a.key.compareTo(b.key));

    state = ApiActionQueueState(actions, paused, submitting, error);

    _removeListener = addListener((state) {
      if (!state.paused && !state.submitting && state.actions.isNotEmpty && state.error == null) {
        _sendNextAction();
      }
    });
    account.initialized.then((value) => _sendNextAction());
  }

  @protected
  @override
  Future<void> delete() async {
    OTL.logger?.d('[actions][${account.id}] Closing');
    super.delete();
    _removeListener();
    _actionsBox.deleteFromDisk();
  }

  String generateDescription(ApiAction<Account<R>> action) {
    return action.generateDescription(account);
  }

  Future<void> addAction(ApiAction<Account<R>> action) async {
    if (closed) return;
    OTL.logger?.d('[actions][${account.id}] Adding action: ${action.generateDescription(account)}');
    await action.applyOptimisticUpdate(account);
    _actionsBox.add(action);
    state = ApiActionQueueState([...actions, action], paused, submitting, error);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (closed) return;
    if (index >= state.actions.length || (index == 0 && submitting)) {
      return;
    }

    final actions = List.of(state.actions);
    final action = actions.removeAt(index);

    OTL.logger?.d('[actions][${account.id}] Removing action: ${action.generateDescription(account)}');
    final error = index == 0 ? null : this.error;
    _actionsBox.deleteAt(index);
    state = ApiActionQueueState(actions, paused, submitting, error);

    return action.revertOptimisticUpdate(account);
  }

  void pause() {
    OTL.logger?.d('[actions][${account.id}] Pausing');
    state = ApiActionQueueState(state.actions, true, submitting, error);
  }

  void resume() {
    OTL.logger?.d('[actions][${account.id}] Resuming');
    state = ApiActionQueueState(state.actions, false, submitting, null);
  }

  void _sendNextAction() async {
    await account.initialized;
    if (closed || state.actions.isEmpty || this.error != null || paused || submitting) {
      return;
    }

    state = ApiActionQueueState(state.actions, paused, true, null);

    final action = state.actions.first;
    OTL.logger?.d('[actions][${account.id}] Submitting Action: ${action.generateDescription(account)}');
    final error = await account.api.sendRequest(action);
    final actions = (error == null) ? state.actions.sublist(1) : state.actions;
    if (error == null) {
      OTL.logger?.d('[actions][${account.id}] Successfully completed');
      if (!closed) {
        _actionsBox.deleteAt(0);
      }
    } else {
      OTL.logger?.d('[actions][${account.id}] Error: ${error.message}');
    }
    state = ApiActionQueueState(actions, paused, false, error);
  }

  @override
  String toString() {
    return 'ApiActionQueue(account: ${account.id}, _paused: $paused, _submitting: $submitting, _error: $error, closed: $closed)';
  }
}
