part of 'api.dart';

const _boxNamePersist = 'api';

const _keyBaseApiUrl = 'baseApiUrl';
const _keyLoginSession = 'loginSession';

abstract class ApiCubit<S extends ApiSession> extends Cubit<ApiState<S>> {
  final Client _client = Client();
  final Uri? _fixedApiBase;
  final processingResponses = ValueNotifier<int>(0);
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

      apiBase =
          _fixedApiBase ?? Uri.tryParse(box.get(_keyBaseApiUrl) ?? '') ?? Uri();

      final session = await initialize(json
          .decode(_persist.get(_keyLoginSession) ?? '{}')
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

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(apiBase);
    builder.path += path;
    return builder;
  }

  @nonVirtual
  Future<String?> login(BaseRequest request, Uri apiBase) async {
    if (state is! ApiStateLoggedOut) {
      return "Not Logged Out";
    }

    emit(const ApiStateLoggingIn());
    try {
      final response = await _sendRequest(request);
      final error = await processLoginResponse(response);
      if (error == null) {
        this.apiBase = apiBase;
      }
      return error;
    } finally {
      // Failsafe, in case there was an error in parseResponseString
      if (state is ApiStateLoggingIn) {
        emit(const ApiStateLoggedOut());
      }
    }
  }

  void registerOngoingOperation(Completer completer) {
    processingResponses.value = processingResponses.value + 1;
    completer.future.then(
        (value) => processingResponses.value = processingResponses.value - 1);
  }

  Future<StreamedResponse> _sendRequest(BaseRequest request) async {
    debugPrint('[api] Sending request to ${request.url}');
    final session = state.session;
    populateHeaders(request.headers, session);
    final response = await _client.send(request);

    final sessionId = state.session?.sessionId;
    if (state is ApiStateLoggingOut || sessionId != session?.sessionId)
      throw Exception("Invalid Session");

    return response;
  }

  Future<void> logout() async {
    if (state is! ApiStateLoggedIn) {
      return;
    }
    debugPrint('[api] Logging Out');
    emit(const ApiStateLoggingOut());

    final apiBase = this.apiBase;
    await _persist.clear();
    this.apiBase = apiBase;

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
  FutureOr<String?> processLoginResponse(StreamedResponse response);

  @protected
  Future<void> clear();
}
