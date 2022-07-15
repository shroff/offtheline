import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';

import 'api_action.dart';
import 'domain.dart';
import 'domain_hooks.dart';
import 'logger.dart';

class ApiActionQueue<R> with ChangeNotifier, DomainHooks<R> {
  late final Box<ApiAction<Domain<R>>> _actionsBox;
  late final List<ApiAction> _actions;
  Iterable<ApiAction> get actions => List.unmodifiable(_actions);

  bool _paused = false;
  bool get paused => _paused;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  ApiActionQueue();

  @protected
  @override
  Future<void> initialize(Domain<R> domain) async {
    logger?.d('[actions][${domain.id}] Initializing');
    super.initialize(domain);

    _actionsBox = await domain.openBox('actions');
    _actions = _actionsBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    _actionsBox.watch().listen((event) {
      notifyListeners();
      _sendNextAction();
    });
    domain.initialized.then((value) => _sendNextAction());
  }

  @protected
  @override
  Future<void> close() async {
    logger?.d('[actions][${domain.id}] Closing');
    super.close();
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
    _actions.add(action);
    _actionsBox.add(action);
    _actionsBox.flush();
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (closed) return;
    if (index >= _actions.length || (index == 0 && submitting)) {
      return;
    }

    final action = _actions.removeAt(index);
    if (revert) {
      await action.revertOptimisticUpdate(domain);
    }

    logger?.i(
        '[actions][${domain.id}] Removing action: ${action.generateDescription(domain)}');
    if (index == 0) {
      _error = null;
    }
    _actionsBox.deleteAt(index);
    _actionsBox.flush();
  }

  void pause() {
    logger?.d('[actions][${domain.id}] Pausing');
    _paused = true;
    notifyListeners();
  }

  void resume() {
    logger?.d('[actions][${domain.id}] Resuming');
    _error = null;
    _paused = false;
    _sendNextAction();
    notifyListeners();
  }

  void _sendNextAction() async {
    if (closed ||
        _actions.isEmpty ||
        (this.error?.isNotEmpty ?? false) ||
        paused ||
        submitting) {
      return;
    }

    _submitting = true;
    notifyListeners();

    final action = _actions[0];
    logger?.i(
        '[actions][${domain.id}] Submitting ${action.generateDescription(domain)}');
    final request = action.createRequest(domain.api);

    _error = await domain.api.sendRequest(request);
    _submitting = false;
    notifyListeners();

    if (error == null) {
      removeActionAt(0, revert: false);
    }
  }

  @override
  String toString() {
    return 'ApiActionQueue(domain: ${domain.id}, _paused: $_paused, _submitting: $_submitting, _error: $_error, closed: $closed)';
  }
}
