part of 'api.dart';

class ApiState<S extends ApiSession> {
  final bool ready;
  final Uri baseApiUrl;
  final S? loginSession;

  bool get isSignedIn => loginSession != null;

  ApiState._({
    this.ready = false,
    required this.baseApiUrl,
    this.loginSession,
  });

  factory ApiState.init() {
    return ApiState._(
      ready: false,
      baseApiUrl: Uri(),
    );
  }

  ApiState<S> copyWith({
    bool? ready,
    Uri? baseApiUrl,
    S? loginSession,
  }) {
    return ApiState._(
      ready: ready ?? this.ready,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      loginSession: loginSession ?? this.loginSession,
    );
  }

  @override
  String toString() {
    return 'ApiState(ready: $ready, baseApiUrl: $baseApiUrl, loginSession: $loginSession';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ApiState<S> &&
        o.ready == ready &&
        o.baseApiUrl == baseApiUrl &&
        o.loginSession == loginSession;
  }

  @override
  int get hashCode {
    return ready.hashCode ^ baseApiUrl.hashCode ^ loginSession.hashCode;
  }
}
