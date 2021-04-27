part of 'api.dart';

const _boxNamePersist = 'apiMetadata';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';

typedef ApiActionDeserializer<S extends ApiSession, T extends ApiCubit<S>>
    = ApiAction<T> Function(Map<String, dynamic> props, dynamic data);

typedef ResponseProcessor = FutureOr<void> Function(
    Map<String, dynamic> response);

abstract class ApiCubit<S extends ApiSession> extends Cubit<ApiState<S>> {
  final BaseClient _client = createHttpClient();
  final processingResponses = ValueNotifier<int>(0);
  final List<ResponseProcessor> _responseProcessors = [];
  final Uri? _fixedApiBase;
  late final Box _persist;

  Uri _apiBase = Uri();
  bool get canChangeApiBase => _fixedApiBase == null;
  Uri get apiBase => _fixedApiBase ?? _apiBase;
  set apiBase(Uri value) {
    if (canChangeApiBase) {
      _apiBase = value;
      _persist.put(_keyBaseApiUrl, value.toString());
    }
  }

  Map<String, String> headers = Map.unmodifiable({});

  ApiCubit({
    Uri? fixedApiBase,
  })  : this._fixedApiBase = fixedApiBase,
        super(const ApiStateInitializing()) {
    debugPrint('[api] Initializing');

    Hive.openBox(_boxNamePersist).then((box) async {
      _persist = box;

      apiBase = _fixedApiBase ??
          Uri.tryParse(box.get(_keyLoginSession, defaultValue: '')) ??
          Uri();

      final session = await initialize(json
          .decode(_persist.get(_keyLoginSession, defaultValue: '{}'))
          .cast<String, dynamic>());
      if (session != null) {
        emit(ApiStateLoggedIn(session));
      } else {
        emit(const ApiStateLoggedOut());
      }
      debugPrint('[api] Ready');
    });
  }

  @override
  void onChange(Change<ApiState<S>> change) {
    super.onChange(change);

    _persist.put(_keyLoginSession, change.nextState.session?.toJson());
    headers = Map.unmodifiable(populateHeaders({}, change.nextState.session));
  }

  E? getMetadata<E>(String key, {E? defaultValue}) {
    return _persist.get(key, defaultValue: defaultValue);
  }

  Future<void> putMetadata<E>(String key, E value) {
    return _persist.put(key, value);
  }

  void addResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.remove(processor);
  }

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(apiBase);
    builder.path += path;
    return builder;
  }

  Future<String?> login(BaseRequest request, Uri apiBase) async {
    if (state is! ApiStateLoggedOut) {
      return "Not Logged Out";
    }

    emit(const ApiStateLoggingIn());
    final error = await sendRequest(request);
    if (error == null) {
      this.apiBase = apiBase;
    }

    // Failsafe, in case there was an error in parseResponseString
    if (state is ApiStateLoggingIn) {
      emit(const ApiStateLoggedOut());
    }

    return error;
  }

  Future<String?> sendRequest(BaseRequest request) async {
    debugPrint('[api] Sending request to ${request.url}');
    final session = state.session;
    populateHeaders(request.headers, session);
    try {
      final response = await _client.send(request);
      String responseString = await response.stream.bytesToString();

      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(
          responseString,
          requestSession: session,
        );
        return null;
      } else {
        return responseString;
      }
    } catch (e) {
      if (e is SocketException) {
        return 'Server Unreachable';
      } else {
        return e.toString();
      }
    }
  }

  Future<void> parseResponseString(
    String responseString, {
    required S? requestSession,
  }) async {
    if (responseString.isNotEmpty) {
      final sessionId = state.session?.sessionId;
      if (state is ApiStateLoggingOut || sessionId != requestSession?.sessionId)
        return;

      processingResponses.value = processingResponses.value + 1;

      try {
        final responseMap = json.decode(responseString) as Map<String, dynamic>;
        debugPrint('[api] Parsing response');
        S? parsedSession = await processResponse(responseMap);
        for (final processResponse in _responseProcessors) {
          await processResponse(responseMap);
        }
        if (parsedSession != null) {
          emit(ApiStateLoggedIn(parsedSession));
        } else {
          logout();
        }
      } finally {
        processingResponses.value = processingResponses.value - 1;
        debugPrint('[api] Response parsed');
      }
    }
  }

  Future<void> logout() async {
    if (state is! ApiStateLoggedIn) {
      return;
    }
    debugPrint('[api] Logging Out');

    emit(const ApiStateLoggingOut());

    await _persist.clear();
    await clear();

    if (processingResponses.value != 0) {
      final completer = Completer();
      final callback = () {
        if (processingResponses.value == 0) {
          completer.complete();
        }
      };
      processingResponses.addListener(callback);
      await completer.future;
      processingResponses.removeListener(callback);
    }

    emit(const ApiStateLoggedOut());
  }

  @protected
  FutureOr<S?> initialize(Map<String, dynamic> sessionMap);

  @protected
  Map<String, String> populateHeaders(Map<String, String> headers, S? session);

  @protected
  FutureOr<S?> processResponse(Map<String, dynamic> responseMap);

  @protected
  Future<void> clear();
}
