part of 'api.dart';

const _keyActions = 'actions';
const _keyActionName = 'name';
const _keyActionProps = 'props';
const _keyActionData = 'data';

typedef ApiActionDeserializer<A extends ApiClient> = ApiAction<A> Function(
    Map<String, dynamic> props, dynamic data);

typedef ResponseProcessor = FutureOr<void> Function(
    Map<String, dynamic> response);

abstract class ApiClient with ChangeNotifier {
  final ongoingOperations = ValueNotifier<int>(0);
  final Client _client = Client();
  final Uri _apiBase;
  final List<ResponseProcessor> _responseProcessors = [];

  Map<String, String> get requestHeaders;
  bool _closed = false;
  @protected
  bool get closed => _closed;

  List<ApiAction> _actions;
  Iterable<ApiAction> get actions => List.unmodifiable(_actions);

  bool _paused = false;
  bool get paused => _paused;

  bool _submitting = false;
  bool get submitting => _submitting;

  String? _error;
  String? get error => _error;

  ApiClient({
    required Uri apiBaseUrl,
    required List<ApiAction> actions,
  })  : this._apiBase = apiBaseUrl,
        this._actions = actions,
        super() {
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

  void registerOngoingOperation(Future future) {
    ongoingOperations.value = ongoingOperations.value + 1;
    future
        .then((value) => ongoingOperations.value = ongoingOperations.value - 1);
  }

  @nonVirtual
  Future<void> logout() async {
    debugPrint('[api] Logging Out');

    if (closed) return;
    _closed = true;

    _actions.clear();

    // Wait for pending operations
    if (ongoingOperations.value != 0) {
      final completer = Completer();
      final callback = () {
        if (ongoingOperations.value == 0) {
          completer.complete();
        }
      };
      ongoingOperations.addListener(callback);
      await completer.future;
      ongoingOperations.removeListener(callback);
    }

    await clear();
  }

  @protected
  @mustCallSuper
  Future<void> clear();

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(_apiBase);
    builder.path += path;
    return builder;
  }

  E? getMetadata<E>(String key, {E? defaultValue});

  Future<void> putMetadata<E>(String key, E value);

  void addResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.remove(processor);
  }

  Future<String?> sendRequest(BaseRequest request) async {
    if (closed) return "Closed";
    final completer = Completer();
    registerOngoingOperation(completer.future);
    try {
      debugPrint('[api] Sending request to ${request.url}');
      request.headers.addAll(requestHeaders);
      final response = await _client.send(request);

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
    } finally {
      completer.complete();
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

  Future<void> addAction(ApiAction action) async {
    if (closed) return;
    await action.applyOptimisticUpdate(this);
    debugPrint(
        '[actions] Request enqueued: ${action.generateDescription(this)}');
    _actions.add(action);
  }

  Future<void> removeActionAt(int index, {bool revert = true}) async {
    if (closed) return;
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
    final request = action.createRequest(this);

    _error = await sendRequest(request);
    _submitting = false;
    notifyListeners();

    if (error == null) {
      removeActionAt(0, revert: false);
    }
  }
}
