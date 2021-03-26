part of 'api_cubit.dart';

class ApiState<D extends Datastore, U extends ApiUser,
    T extends ApiCubit<D, U, T>> {
  final bool ready;
  final Uri baseApiUrl;
  final LoginSession<U>? loginSession;
  final ActionQueueState<D, U, T> actionQueueState;
  final FetchState fetchState;

  ApiState._({
    this.ready = false,
    required this.baseApiUrl,
    this.loginSession,
    required this.actionQueueState,
    this.fetchState = const FetchState(),
  });

  factory ApiState.init() {
    return ApiState._(
      ready: false,
      baseApiUrl: Uri(),
      actionQueueState: ActionQueueState<D, U, T>(),
    );
  }

  ApiState<D, U, T> copyWith({
    bool? ready,
    Uri? baseApiUrl,
    LoginSession<U>? loginSession,
    ActionQueueState<D, U, T>? actionQueueState,
    FetchState? fetchState,
    bool allowNullLoginSession = false,
  }) {
    return ApiState._(
      ready: ready ?? this.ready,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      loginSession:
          loginSession ?? (allowNullLoginSession ? null : this.loginSession),
      actionQueueState: actionQueueState ?? this.actionQueueState,
      fetchState: fetchState ?? this.fetchState,
    );
  }

  @override
  String toString() {
    return 'ApiState(ready: $ready, baseApiUrl: $baseApiUrl, loginSession: $loginSession, actionQueueState: $actionQueueState, fetchState: $fetchState)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ApiState<D, U, T> &&
        o.ready == ready &&
        o.baseApiUrl == baseApiUrl &&
        o.loginSession == loginSession &&
        o.actionQueueState == actionQueueState &&
        o.fetchState == fetchState;
  }

  @override
  int get hashCode {
    return ready.hashCode ^
        baseApiUrl.hashCode ^
        loginSession.hashCode ^
        actionQueueState.hashCode ^
        fetchState.hashCode;
  }
}

class LoginSession<U extends ApiUser> {
  final String sessionId;
  final int gid;
  final U user;

  LoginSession(
    this.sessionId,
    this.gid,
    this.user,
  );

  LoginSession<U> copyWith({
    String? sessionId,
    int? gid,
    int? usedIds,
    U? user,
  }) {
    return LoginSession<U>(
      sessionId ?? this.sessionId,
      gid ?? this.gid,
      user ?? this.user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'gid': gid,
      'user': user?.toMap(),
    };
  }

  factory LoginSession.fromMap(
      Map<String, dynamic> map, ApiUserParser<U> parseUser) {
    if (map == null) return null;

    final session = LoginSession<U>(
      map['sessionId'],
      map['gid'],
      parseUser(map['user']),
    );

    if (session.sessionId == null ||
        session.gid == null ||
        session.user == null) {
      return null;
    }

    return session;
  }

  String toJson() => json.encode(toMap());

  factory LoginSession.fromJson(
          String source, ApiUserParser<U> parseUser) =>
      (source == null || source.isEmpty)
          ? null
          : LoginSession.fromMap(json.decode(source), parseUser);

  @override
  String toString() {
    return 'LoginSession(sessionId: $sessionId, gid: $gid, user: $user)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is LoginSession<U> &&
        o.sessionId == sessionId &&
        o.gid == gid &&
        o.user == user;
  }

  @override
  int get hashCode {
    return sessionId.hashCode ^ gid.hashCode ^ user.hashCode;
  }
}

class ActionQueueState<D extends Datastore, U extends ApiUser,
    T extends ApiCubit<D, U, T>> {
  final Iterable<ApiAction<D, U, T>> actions;
  final bool paused;
  final bool submitting;
  final String? error;

  const ActionQueueState({
    this.actions = const [],
    this.paused = false,
    this.submitting = false,
    this.error,
  });

  ActionQueueState<D, U, T> copyWithPaused(bool paused) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: null,
    );
  }

  ActionQueueState<D, U, T> copyWithSubmitting(bool submitting, String? error) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  ActionQueueState<D, U, T> copyWithActions(
      Iterable<ApiAction<D, U, T>> actions,
      {bool resetError = false}) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: resetError ? null : error,
    );
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ActionQueueState<D, U, T> &&
        o.actions == actions &&
        o.paused == paused &&
        o.submitting == submitting &&
        o.error == error;
  }

  @override
  int get hashCode {
    return actions.hashCode ^
        paused.hashCode ^
        submitting.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'ActionQueueState(actions: $actions, paused: $paused, submitting: $submitting, error: $error)';
  }
}

class FetchState {
  final bool fetching;
  final bool connected;
  final String? error;

  const FetchState({
    this.fetching = false,
    this.connected = false,
    this.error,
  });

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is FetchState &&
        o.fetching == fetching &&
        o.connected == connected &&
        o.error == error;
  }

  @override
  int get hashCode => fetching.hashCode ^ connected.hashCode ^ error.hashCode;

  @override
  String toString() =>
      'FetchState(fetching: $fetching, connected: $connected, error: $error)';
}
