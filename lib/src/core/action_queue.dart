import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

import '../actions/api_action.dart';
import 'api_error_response.dart';
import 'domain.dart';
import 'domain_hooks.dart';
import 'logger.dart';

class ApiActionQueueState {
  final List<ApiAction> actions;
  final bool paused;
  final bool submitting;
  final ApiErrorResponse? error;

  ApiActionQueueState(this.actions, this.paused, this.submitting, this.error);
}

class ApiActionQueue<R> extends StateNotifier<ApiActionQueueState>
    with DomainHooks<R>, LocatorMixin {
  late final Box<ApiAction<Domain<R>>> _actionsBox;
  late final Function() _removeListener;
  Iterable<ApiAction> get actions => List.unmodifiable(state.actions);

  bool get paused => state.paused;

  bool get submitting => state.submitting;

  ApiErrorResponse? get error => state.error;

  ApiActionQueue() : super(ApiActionQueueState([], false, false, null));

  @protected
  @override
  Future<void> initialize(Domain<R> domain) async {
    logger?.d('[actions][${domain.id}] Initializing');
    super.initialize(domain);

    _actionsBox = await domain.openBox('actions');
    final actions = _actionsBox.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    state = ApiActionQueueState(actions, paused, submitting, error);

    _removeListener = addListener((state) {
      if (!state.paused &&
          !state.submitting &&
          state.actions.isNotEmpty &&
          state.error == null) {
        _sendNextAction();
      }
    });
    domain.initialized.then((value) => _sendNextAction());
  }

  @protected
  @override
  Future<void> close() async {
    logger?.d('[actions][${domain.id}] Closing');
    super.close();
    _removeListener();
    _actionsBox.close();
  }

  String generateDescription(ApiAction<Domain<R>> action) {
    return action.generateDescription(domain);
  }

  Future<void> addAction(ApiAction<Domain<R>> action) async {
    if (closed) return;
    logger?.i(
        '[actions][${domain.id}] Adding action: ${action.generateDescription(domain)}');
    await action.applyOptimisticUpdate(domain);
    _actionsBox.add(action);
    _actionsBox.flush();
    state =
        ApiActionQueueState([...actions, action], paused, submitting, error);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (closed) return;
    if (index >= state.actions.length || (index == 0 && submitting)) {
      return;
    }

    final actions = List.of(state.actions);
    final action = actions.removeAt(index);

    logger?.d(
        '[actions][${domain.id}] Removing action: ${action.generateDescription(domain)}');
    final error = index == 0 ? null : this.error;
    _actionsBox.deleteAt(index);
    _actionsBox.flush();
    state = ApiActionQueueState(actions, paused, submitting, error);

    return action.revertOptimisticUpdate(domain);
  }

  void pause() {
    logger?.d('[actions][${domain.id}] Pausing');
    state = ApiActionQueueState(state.actions, true, submitting, error);
  }

  void resume() {
    logger?.d('[actions][${domain.id}] Resuming');
    state = ApiActionQueueState(state.actions, false, submitting, null);
  }

  void _sendNextAction() async {
    if (closed ||
        state.actions.isEmpty ||
        this.error != null ||
        paused ||
        submitting) {
      return;
    }

    state = ApiActionQueueState(state.actions, paused, true, null);

    final action = state.actions.first;
    logger?.d(
        '[actions][${domain.id}] Submitting ${action.generateDescription(domain)}');
    final request = action.createRequest(domain.api);

    final error = await domain.api.sendRequest(request, tag: action.tag);
    final actions = (error == null) ? state.actions.sublist(1) : state.actions;
    if (error == null) {
      logger?.d('[actions][${domain.id}] Success');
      if (!closed) {
        _actionsBox.deleteAt(0);
        _actionsBox.flush();
      }
    } else {
      logger?.d('[actions][${domain.id}] Error: $error');
    }
    state = ApiActionQueueState(actions, paused, false, error);
  }

  @override
  String toString() {
    return 'ApiActionQueue(domain: ${domain.id}, _paused: $paused, _submitting: $submitting, _error: $error, closed: $closed)';
  }
}
