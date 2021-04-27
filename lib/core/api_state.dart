part of 'api.dart';

class ApiStateInitializing<S extends ApiSession> extends ApiState<S> {
  const ApiStateInitializing();
}

class ApiStateLoggedOut<S extends ApiSession> extends ApiState<S> {
  const ApiStateLoggedOut();
}

class ApiStateLoggingOut<S extends ApiSession> extends ApiState<S> {
  const ApiStateLoggingOut();
}

class ApiStateLoggedIn<S extends ApiSession> extends ApiState<S> {
  final S session;

  ApiStateLoggedIn(this.session);

  @override
  String toString() => 'ApiStateLoggedIn(session: $session)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ApiStateLoggedIn<S> && other.session == session;
  }

  @override
  int get hashCode => session.hashCode;
}

@immutable
abstract class ApiState<S extends ApiSession> {
  S? get session => null;

  const ApiState();
}
