import 'dart:async';

import 'package:appcore/appcore.dart';
import 'package:flutter/foundation.dart';

import 'domain.dart';
import 'domain_hooks.dart';

const _boxKeyActions = "__actions";

class ApiActionQueue<R> with ChangeNotifier, DomainHooks<R> {
  late final List<ApiAction> _actions;
  Iterable<ApiAction> get actions => List.unmodifiable(_actions);

  bool _closed = false;

  bool _paused = false;
  bool get paused => _paused;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  ApiActionQueue();

  @protected
  Future<void> initialize(Domain<R> domain) async {
    super.initialize(domain);

    _actions = domain.getMetadata(_boxKeyActions) ?? [];
    domain.watchMetadata(key: _boxKeyActions).listen((event) {
      notifyListeners();
      _sendNextAction();
    });
    _sendNextAction();
  }

  String generateDescription(ApiAction<Domain<R>> action) {
    return action.generateDescription(domain);
  }

  Future<void> addAction(ApiAction action) async {
    if (_closed) return;
    await action.applyOptimisticUpdate(domain);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(domain)}');
    _actions.add(action);
    domain.putMetadata(_boxKeyActions, _actions);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (_closed) return;
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
    if (index == 0 && error != null) {
      _error = null;
    }
    domain.putMetadata(_boxKeyActions, _actions);
  }

  void pauseActionQueue() {
    debugPrint('[actions] Pausing');
    _paused = true;
    notifyListeners();
  }

  void resumeActionQueue() {
    debugPrint('[actions] Resuming');
    _paused = false;
    _sendNextAction();
    notifyListeners();
  }

  void _sendNextAction() async {
    if (_closed ||
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
}
