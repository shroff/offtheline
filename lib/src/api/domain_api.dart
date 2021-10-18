part of 'api.dart';

const _keyActions = 'actions';
const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

typedef ApiActionDeserializer<T extends ApiCubit> = ApiAction<T> Function(
    Map<String, dynamic> props, dynamic data);

typedef ResponseProcessor = FutureOr<void> Function(
    Map<String, dynamic> response);

abstract class DomainApi<T extends ApiCubit> with ChangeNotifier {
  final T _api;
  final List<ResponseProcessor> _responseProcessors = [];
  Map<String, String> get headers => _api.headers;

  List<ApiAction<T>> _actions;
  Iterable<ApiAction<T>> get actions => List.unmodifiable(_actions);

  bool _paused = false;
  bool get paused => _paused;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  DomainApi._(this._api, this._actions) : super() {
    _sendNextAction();
  }

  // ApiAction<T> _deserializeAction(Map<dynamic, dynamic> actionMap) {
  //   final name = actionMap[_keyActionName];
  //   assert(_deserializers.containsKey(name));
  //   final props = actionMap[_keyActionProps] as Map;
  //   final data = actionMap[_keyActionData];
  //   final action = _deserializers[name]!(props.cast<String, dynamic>(), data);
  //   return action;
  // }

  // _actions.map((action) => {
  //       _keyActionName: action.name,
  //       _keyActionProps: action.toMap(),
  //       _keyActionData: action.binaryData,
  //     })

  Future<void> clear() async {
    _actions.clear();
    notifyListeners();
  }

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path);

  E? getMetadata<E>(String key, {E? defaultValue});

  Future<void> putMetadata<E>(String key, E value);

  void addResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.remove(processor);
  }

  Future<String?> sendRequest(BaseRequest request) async {
    try {
      final response = await _api._sendRequest(request);
      final responseString = await response.stream.bytesToString();
      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(responseString);
        return null;
      } else {
        return processErrorResponse(responseString);
      }
    } on SocketException {
      return "Server Unreachable";
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> parseResponseString(String responseString) async {
    final completer = Completer<void>();
    try {
      debugPrint('[api] Parsing response');
      if (responseString.isNotEmpty) {
        final responseMap = json.decode(responseString) as Map<String, dynamic>;
        await processResponse(responseMap);
        for (final processResponse in _responseProcessors) {
          await processResponse(responseMap);
        }
        _sendNextAction();
      }
    } finally {
      completer.complete();
      debugPrint('[api] Response parsed');
    }
  }

  @protected
  FutureOr<void> processResponse(Map<String, dynamic> responseMap);

  @protected
  FutureOr<String> processErrorResponse(String errorString) => errorString;

  Future<void> addAction(ApiAction<T> action) async {
    await action.applyOptimisticUpdate(this);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(this)}');
    _actions.add(action);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (index >= _actions.length || (index == 0 && submitting)) {
      return;
    }

    final action = _actions.removeAt(index);
    if (revert) {
      await action.revertOptimisticUpdate(this);
    }

    if (kDebugMode) {
      debugPrint(
          '[actions] Deleting request: ${action.generateDescription(this)}');
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
    if (_actions.isEmpty ||
        (this.error?.isNotEmpty ?? false) ||
        paused ||
        submitting) {
      return;
    }

    _submitting = true;
    notifyListeners();

    final action = _actions[0];
    final request = action.createRequest(this);

    _error = await sendRequest(request);
    _submitting = false;
    notifyListeners();

    if (error == null) {
      removeActionAt(0, revert: false);
    }
  }
}
