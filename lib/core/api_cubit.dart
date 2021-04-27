part of 'api.dart';

const _boxNamePersist = 'apiMetadata';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';

typedef ApiActionDeserializer<S extends ApiSession, T extends ApiCubit<S>>
    = ApiAction<T> Function(Map<String, dynamic> props, dynamic data);

mixin ApiHooks {
  FutureOr<void> processResponse(Map<String, dynamic> response) {}
}

abstract class ApiCubit<S extends ApiSession> extends Cubit<ApiState<S>>
    with ApiHooks {
  late final Box _persist;
  final BaseClient _client = createHttpClient();
  Map<String, String> headers = Map.unmodifiable({});
  late final List<ApiHooks> _hooks;

  final Uri? _fixedApiBase;
  Uri _apiBase = Uri();
  Uri get apiBase => _fixedApiBase ?? _apiBase;
  bool get canChangeApiBase => _fixedApiBase == null;
  set apiBase(Uri value) {
    if (canChangeApiBase) {
      _apiBase = value;
      _persist.put(_keyBaseApiUrl, value.toString());
    }
  }

  ApiCubit({
    Uri? fixedApiBase,
  })  : this._fixedApiBase = fixedApiBase,
        super(const ApiStateInitializing()) {
    debugPrint('[api] Initializing');

    Hive.openBox(_boxNamePersist).then((box) async {
      _persist = box;
      _hooks = [];

      await initialize();

      apiBase = _fixedApiBase ??
          Uri.tryParse(box.get(_keyLoginSession, defaultValue: '')) ??
          Uri();

      final session = parseSession(json
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

  void registerHook(ApiHooks hook) {
    _hooks.add(hook);
  }

  void unregisterHook(ApiHooks hook) {
    _hooks.remove(hook);
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
    final error = await sendRequest(request);
    if (error == null) {
      this.apiBase = apiBase;
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
      if (sessionId != requestSession?.sessionId) return;

      final responseMap = json.decode(responseString) as Map<String, dynamic>;
      debugPrint('[api] Parsing response');
      await processResponseMap(responseMap);
      for (final hook in _hooks) {
        await hook.processResponse(responseMap);
      }
      debugPrint('[api] Response parsed');
    }
  }

  Future<void> logout() async {
    debugPrint('[api] Logging Out');

    emit(const ApiStateLoggingOut());

    await _persist.clear();
    await clear();
    // TODO: Wait for any ongoing connections to finish?

    emit(const ApiStateLoggedOut());
  }

  @protected
  Future<void> initialize();

  @protected
  S? parseSession(Map<String, dynamic> map);

  @protected
  Map<String, String> populateHeaders(Map<String, String> headers, S? session);

  @protected
  FutureOr<void> processResponseMap(Map<String, dynamic> responseMap);

  @protected
  Future<void> clear();
}
