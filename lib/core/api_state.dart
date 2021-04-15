part of 'api_cubit.dart';

class ApiState<D extends Datastore, S extends ApiSession,
    T extends ApiCubit<D, S, T>> {
  final bool ready;
  final Uri baseApiUrl;
  final S? loginSession;
  final ActionQueueState<D, S, T> actionQueueState;

  ApiState._({
    this.ready = false,
    required this.baseApiUrl,
    this.loginSession,
    required this.actionQueueState,
  });

  factory ApiState.init() {
    return ApiState._(
      ready: false,
      baseApiUrl: Uri(),
      actionQueueState: ActionQueueState<D, S, T>(),
    );
  }

  ApiState<D, S, T> copyWith({
    bool? ready,
    Uri? baseApiUrl,
    S? loginSession,
    ActionQueueState<D, S, T>? actionQueueState,
    bool allowNullLoginSession = false,
  }) {
    return ApiState._(
      ready: ready ?? this.ready,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      loginSession:
          loginSession ?? (allowNullLoginSession ? null : this.loginSession),
      actionQueueState: actionQueueState ?? this.actionQueueState,
    );
  }

  @override
  String toString() {
    return 'ApiState(ready: $ready, baseApiUrl: $baseApiUrl, loginSession: $loginSession, actionQueueState: $actionQueueState';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ApiState<D, S, T> &&
        o.ready == ready &&
        o.baseApiUrl == baseApiUrl &&
        o.loginSession == loginSession &&
        o.actionQueueState == actionQueueState;
  }

  @override
  int get hashCode {
    return ready.hashCode ^
        baseApiUrl.hashCode ^
        loginSession.hashCode ^
        actionQueueState.hashCode;
  }
}

abstract class ApiSession {
  String get sessionId;
  int get gid;

  Map<String, dynamic> toMap();

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '${this.runtimeType}(sessionId: $sessionId, gid: $gid)';
  }
}

class ActionQueueState<D extends Datastore, S extends ApiSession,
    T extends ApiCubit<D, S, T>> {
  final Iterable<ApiAction<D, S, T>> actions;
  final bool paused;
  final bool submitting;
  final String? error;

  const ActionQueueState({
    this.actions = const [],
    this.paused = false,
    this.submitting = false,
    this.error,
  });

  ActionQueueState<D, S, T> copyWithPaused(bool paused) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: null,
    );
  }

  ActionQueueState<D, S, T> copyWithSubmitting(bool submitting, String? error) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  ActionQueueState<D, S, T> copyWithActions(
      Iterable<ApiAction<D, S, T>> actions,
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

    return o is ActionQueueState<D, S, T> &&
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
