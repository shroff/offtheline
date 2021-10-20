part of 'api_client.dart';

class ApiActionQueue with ChangeNotifier {
  final ApiClient api;
  late final Box<ApiAction> _actions;
  bool _closed = false;

  Iterable<ApiAction> get actions => List.unmodifiable(_actions.values);
  bool get closed => _closed;

  bool _paused = false;
  bool get paused => _paused;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  ApiActionQueue(this.api);

  Future<void> initialize(String name) async {
    this._actions = await Hive.openBox(name);
    _actions.watch().listen((event) {
      notifyListeners();
    });
    _sendNextAction();
  }

  Future<void> close() async {
    if (closed) return;
    _closed = true;
    _actions.clear();
    _actions.close();
    _actions.deleteFromDisk();
  }

  Future<void> addAction(ApiAction action) async {
    if (closed) return;
    await action.applyOptimisticUpdate(api);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(api)}');
    _actions.add(action);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (closed) return;
    if (index >= _actions.length || (index == 0 && submitting)) {
      return;
    }

    final action = _actions.getAt(index)!;
    _actions.deleteAt(index);
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
    notifyListeners();
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

    final action = _actions.getAt(0)!;
    final request = action.createRequest(api);

    _error = await api.sendRequest(request);
    _submitting = false;
    notifyListeners();

    if (error == null) {
      removeActionAt(0, revert: false);
    }
  }
}
