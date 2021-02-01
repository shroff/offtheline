import 'dart:convert';

import 'package:appcore/core/api_user.dart';
import 'package:appcore/requests/requests.dart';
import 'package:flutter/foundation.dart';

@immutable
class ApiState<U extends ApiUser> {
  final bool ready;
  final Uri baseApiUrl;
  final LoginSession loginSession;
  final ActionQueueState actionQueueState;
  final FetchState fetchState;

  const ApiState({
    this.ready = false,
    this.baseApiUrl,
    this.loginSession,
    this.actionQueueState,
    this.fetchState,
  });

  ApiState<U> copyWith({
    bool ready,
    Uri baseApiUrl,
    LoginSession loginSession,
    ActionQueueState actionQueueState,
    FetchState fetchState,
  }) {
    return ApiState<U>(
      ready: ready ?? this.ready,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      loginSession: loginSession ?? this.loginSession,
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

    return o is ApiState<U> &&
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
    String sessionId,
    int gid,
    int usedIds,
    U user,
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

  bool userHasPermission(int permission) {
    return user.hasPermission(permission);
  }

  String toJson() => json.encode(toMap());

  factory LoginSession.fromJson(String source, ApiUserParser<U> parseUser) =>
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

class ActionQueueState {
  final Iterable<ApiRequest> actions;
  final bool paused;
  final bool submitting;
  final String error;

  ActionQueueState({
    this.actions,
    this.paused = false,
    this.submitting = false,
    this.error = '',
  });

  ActionQueueState copyWithPaused(bool paused) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  ActionQueueState copyWithSubmitting(bool submitting, String error) {
    return ActionQueueState(
      actions: actions,
      paused: paused,
      submitting: submitting,
      error: error,
    );
  }

  ActionQueueState copyWithActions(Iterable<ApiRequest> actions, {bool resetError = false}) {
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

    return o is ActionQueueState &&
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
  final String error;

  FetchState({
    this.fetching = false,
    this.connected = false,
    this.error = '',
  });

  FetchState copyWith({
    bool fetching,
    bool connected,
    String error,
  }) {
    return FetchState(
      fetching: fetching ?? this.fetching,
      connected: connected ?? this.connected,
      error: error,
    );
  }

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
