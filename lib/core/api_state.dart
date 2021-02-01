import 'dart:convert';

import 'package:appcore/core/api_user.dart';
import 'package:appcore/requests/requests.dart';
import 'package:flutter/foundation.dart';

@immutable
class ApiState<U extends ApiUser> {
  final bool ready;
  final Uri baseApiUrl;
  final LoginSession loginSession;
  final bool fetchingUpdates;
  final bool socketConnected;
  final bool actionsPaused;
  final bool actionSubmitting;
  final Iterable<ApiRequest> actions;
  final String fetchError;
  final String actionError;

  const ApiState({
    this.ready = false,
    this.baseApiUrl,
    this.loginSession,
    this.fetchingUpdates = false,
    this.socketConnected = false,
    this.actionsPaused = false,
    this.actionSubmitting = false,
    this.actions,
    this.fetchError = '',
    this.actionError = '',
  });

  ApiState<U> copyWith({
    bool ready,
    Uri baseApiUrl,
    LoginSession loginSession,
    bool fetchingUpdates,
    bool socketConnected,
    bool actionsPaused,
    bool actionSubmitting,
    List<ApiRequest> actions,
    String fetchError,
    String actionError,
  }) {
    return ApiState<U>(
      ready: ready ?? this.ready,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      loginSession: loginSession ?? this.loginSession,
      fetchingUpdates: fetchingUpdates ?? this.fetchingUpdates,
      socketConnected: socketConnected ?? this.socketConnected,
      actionsPaused: actionsPaused ?? this.actionsPaused,
      actionSubmitting: actionSubmitting ?? this.actionSubmitting,
      actions: actions ?? this.actions,
      fetchError: fetchError ?? this.fetchError,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  String toString() {
    return 'ApiState(ready: $ready, baseApiUrl: $baseApiUrl, session: $loginSession, fetchingUpdates: $fetchingUpdates, socketConnected: $socketConnected, actionsPaused: $actionsPaused, actionSubmitting: $actionSubmitting, actions: $actions, fetchError: $fetchError, actionError: $actionError)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
  
    return o is ApiState<U> &&
      o.ready == ready &&
      o.baseApiUrl == baseApiUrl &&
      o.loginSession == loginSession &&
      o.fetchingUpdates == fetchingUpdates &&
      o.socketConnected == socketConnected &&
      o.actionsPaused == actionsPaused &&
      o.actionSubmitting == actionSubmitting &&
      o.actions == actions &&
      o.fetchError == fetchError &&
      o.actionError == actionError;
  }

  @override
  int get hashCode {
    return ready.hashCode ^
        baseApiUrl.hashCode ^
        loginSession.hashCode ^
        fetchingUpdates.hashCode ^
        socketConnected.hashCode ^
        actionsPaused.hashCode ^
        actionSubmitting.hashCode ^
        actions.hashCode ^
        fetchError.hashCode ^
        actionError.hashCode;
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
