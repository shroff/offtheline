part of 'api.dart';

const _boxNamePersist = 'apiMetadata';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';
const _keyActionsPaused = 'actionsPaused';

typedef ApiActionDeserializer<S extends ApiSession, T extends ApiCubit<S, T>>
    = ApiAction<S, T> Function(Map<String, dynamic> props, dynamic data);

abstract class ApiCubit<S extends ApiSession, T extends ApiCubit<S, T>>
    extends Cubit<ApiState<S, T>> {
  final BaseClient _client = createHttpClient();
  final Uri? _fixedBaseApiUrl;

  late final Box _persist;

  bool get isSignedIn => state.isSignedIn;
  bool get canChangeBaseApiUrl => _fixedBaseApiUrl == null;

  bool get canLogIn =>
      state.ready && !isSignedIn && (!kIsWeb || state.baseApiUrl.hasAuthority);

  set baseApiUrl(Uri value) {
    emit(state.copyWith(baseApiUrl: value));
  }

  @protected
  String? get userAgent => null;
  Map<String, String> headers = Map.unmodifiable({});

  ApiCubit({
    Uri? fixedBaseApiUrl,
  })  : this._fixedBaseApiUrl = fixedBaseApiUrl,
        super(ApiState.init()) {
    debugPrint('[api] Initializing');

    Hive.openBox(_boxNamePersist).then((box) async {
      _persist = box;

      await initialize();

      final apiSession = parseSession(json
          .decode(_persist.get(_keyLoginSession, defaultValue: '{}'))
          .cast<String, dynamic>());
      emit(ApiState._(
        ready: true,
        baseApiUrl: _fixedBaseApiUrl ??
            Uri.tryParse(box.get(_keyLoginSession, defaultValue: '')) ??
            Uri(),
        loginSession: apiSession,
      ));
      debugPrint('[api] Ready');
    });
  }

  @override
  void onChange(Change<ApiState<S, T>> change) {
    super.onChange(change);
    if (!change.nextState.ready) return;

    if (change.currentState.baseApiUrl != change.nextState.baseApiUrl) {
      _persist.put(_keyBaseApiUrl, change.nextState.baseApiUrl.toString());
    }

    if (change.currentState.ready) {
      if (change.currentState.loginSession != change.nextState.loginSession) {
        _recomputeHeaders(sessionId: change.nextState.loginSession?.sessionId);
        _persist.put(_keyLoginSession, change.nextState.loginSession?.toJson());
      }
    } else {
      _recomputeHeaders(sessionId: change.nextState.loginSession?.sessionId);
    }
  }

  E? getMetadata<E>(String key, {E? defaultValue}) {
    return _persist.get(key, defaultValue: defaultValue);
  }

  Future<void> putMetadata<E>(String key, E value) {
    return _persist.put(key, value);
  }

  Future<void> logout() async {
    debugPrint('[api] Logging Out');

    emit(ApiState._(baseApiUrl: state.baseApiUrl));

    await clear();
    await _persist.clear();

    // TODO: Wait for any ongoing connections to finish?

    emit(state.copyWith(ready: true));
  }

  @protected
  Future<void> initialize();

  @protected
  Future<void> clear();

  void _recomputeHeaders({String? sessionId}) {
    final headersBuilder = <String, String>{};
    final userAgent = this.userAgent;
    if (userAgent != null) {
      headersBuilder['User-Agent'] = userAgent;
    }
    if (sessionId != null) {
      headersBuilder['Authorization'] = 'SessionId $sessionId';
    }
    headers = Map.unmodifiable(headersBuilder);
  }

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(state.baseApiUrl);
    builder.path += path;
    return builder;
  }

  Future<String?> sendRequest(BaseRequest request,
      {bool authRequired = true}) async {
    debugPrint('[api] Sending request to ${request.url}');
    if (authRequired) {
      request.headers.addAll(headers);
    }
    try {
      final response = await _client.send(request);
      String responseString = await response.stream.bytesToString();

      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(responseString, authRequired: authRequired);
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
    bool authRequired = true,
  }) async {
    if (responseString.isNotEmpty) {
      while (!state.ready) {
        await stream.firstWhere((state) => state.ready);
      }
      if (authRequired && !isSignedIn) return;

      final responseMap = json.decode(responseString) as Map<String, dynamic>;
      final newState = await parseResponse(responseMap);
      if (newState != null) {
        emit(newState);
      }
    }
  }

  @protected
  S? parseSession(Map<String, dynamic> map);

  @protected
  FutureOr<ApiState<S, T>?> parseResponse(Map<String, dynamic> response);
}
