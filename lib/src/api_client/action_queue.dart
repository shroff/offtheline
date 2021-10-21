part of 'api_client.dart';

const _boxKeyActions = "__actions";

class ApiActionQueue with ChangeNotifier {
  final ApiClient api;
  late final List<ApiAction> _actions;
  bool _closed = false;

  Iterable<ApiAction> get actions => List.unmodifiable(_actions);
  bool get closed => _closed;

  bool _paused = false;
  bool get paused => _paused;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  ApiActionQueue(this.api);

  Future<void> initialize() async {
    api._metadataBox.watch(key: _boxKeyActions).listen((event) {
      notifyListeners();
      _sendNextAction();
    });
    _sendNextAction();
  }

  Future<void> close() async {
    if (closed) return;
    _closed = true;
  }

  Future<void> addAction(ApiAction action) async {
    if (closed) return;
    await action.applyOptimisticUpdate(api);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(api)}');
    _actions.add(action);
    api._metadataBox.put(_boxKeyActions, _actions);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (closed) return;
    if (index >= _actions.length || (index == 0 && submitting)) {
      return;
    }

    final action = _actions.removeAt(index);
    if (revert) {
      await action.revertOptimisticUpdate(api);
    }

    if (kDebugMode) {
      debugPrint(
          '[actions] Deleting request: ${action.generateDescription(api)}');
    }
    if (index == 0 && error != null) {
      _error = null;
    }
    api._metadataBox.put(_boxKeyActions, _actions);
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
    final request = action.createRequest(api);

    _error = await api.sendRequest(request);
    _submitting = false;
    notifyListeners();

    if (error == null) {
      removeActionAt(0, revert: false);
    }
  }
}
