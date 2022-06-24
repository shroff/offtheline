import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appcore/appcore.dart';
import 'package:hive/hive.dart';

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
    super.initialize(domain);

    _actionsBox = await domain.openBox('actions');
    _actions = _actionsBox.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    _actionsBox.watch().listen((event) {
      notifyListeners();
      _sendNextAction();
    });
    _sendNextAction();
  }

  @protected
  @override
  Future<void> close() async {
    super.close();
    _actionsBox.close();
  }

  String generateDescription(ApiAction<Domain<R>> action) {
    return action.generateDescription(domain);
  }

  Future<void> addAction(ApiAction<Domain<R>> action) async {
    if (closed) return;
    await action.applyOptimisticUpdate(domain);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(domain)}');
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

    if (kDebugMode) {
      debugPrint(
          '[actions] Deleting request: ${action.generateDescription(domain)}');
    }
    if (index == 0) {
      _error = null;
    }
    _actionsBox.deleteAt(index);
    _actionsBox.flush();
  }

  void pause() {
    debugPrint('[actions] Pausing');
    _paused = true;
    notifyListeners();
  }

  void resume() {
    debugPrint('[actions] Resuming');
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
    return 'ApiActionQueue(_paused: $_paused, _submitting: $_submitting, _error: $_error, closed: $closed)';
  }
}
