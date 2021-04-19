part of 'api.dart';

const _boxNamePersist = 'apiMetadata';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';
const _keyActionsPaused = 'actionsPaused';

typedef ApiActionDeserializer<D extends Datastore<D, S, T>,
        S extends ApiSession, T extends ApiCubit<D, S, T>>
    = ApiAction<D, S, T> Function(Map<String, dynamic> props, dynamic data);

abstract class ApiCubit<D extends Datastore<D, S, T>, S extends ApiSession,
    T extends ApiCubit<D, S, T>> extends Cubit<ApiState<D, S, T>> {
  bool _initializedOnce = false;

  final BaseClient _client = createHttpClient();
  final Uri? _fixedBaseApiUrl;

  final D datastore;

  late Box _persist;

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

  ApiCubit(
    this.datastore, {
    Uri? fixedBaseApiUrl,
  })  : this._fixedBaseApiUrl = fixedBaseApiUrl,
        super(ApiState.init()) {
    debugPrint('[api] Initializing');
    datastore._initialize(this as T);
    _initialize(_fixedBaseApiUrl);
  }

  @override
  void onChange(Change<ApiState<D, S, T>> change) {
    super.onChange(change);
    if (!change.nextState.ready) return;

    Map<String, dynamic> changes = {};
    if (change.currentState.baseApiUrl != change.nextState.baseApiUrl) {
      changes[_keyBaseApiUrl] = change.nextState.baseApiUrl.toString();
    }

    if (change.currentState.ready) {
      if (change.currentState.loginSession != change.nextState.loginSession) {
        _recomputeHeaders(sessionId: change.nextState.loginSession?.sessionId);
        changes[_keyLoginSession] = change.nextState.loginSession?.toJson();
      }
    } else {
      _recomputeHeaders(sessionId: change.nextState.loginSession?.sessionId);
    }

    if (changes.isNotEmpty) {
      _persist.putAll(changes);
    }
  }

  Future<void> _initialize(Uri? baseApiUrl) async {
    await datastore.ready;
    if (!_initializedOnce) {
      _initializedOnce = true;
      await initializeOnce();
    }
    final apiSession = parseSession(json
        .decode(_persist.get(_keyLoginSession, defaultValue: '{}'))
        .cast<String, dynamic>());
    emit(ApiState._(
      ready: true,
      baseApiUrl: baseApiUrl ??
          Uri.tryParse(_persist.get(_keyBaseApiUrl, defaultValue: ''))!,
      loginSession: apiSession,
    ));
    debugPrint('[api] Ready');
  }

  Future<void> logout() async {
    debugPrint('[api] Logging Out');

    emit(ApiState._(baseApiUrl: state.baseApiUrl));

    await Hive.deleteBoxFromDisk(_boxNamePersist);
    datastore.wipe();

    // TODO: Wait for any ongoing connections to finish?

    emit(state.copyWith(ready: true));
  }

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
  FutureOr<void> initializeOnce() {}

  @protected
  S? parseSession(Map<String, dynamic> map);

  @protected
  FutureOr<ApiState<I, D, S, T>?> parseResponse(Map<String, dynamic> response);
}
