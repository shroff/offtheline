import 'package:appcore/core/api_user.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

@immutable
class ApiState<U extends ApiUser> {
  final Uri baseApiUrl;
  final String sessionId;
  final int gid;
  final int usedIds;
  final U user;

  ApiState({
    this.baseApiUrl,
    this.sessionId,
    this.gid,
    this.usedIds,
    this.user,
  });

  bool hasPermission(int permission) {
    return user.hasPermission(permission);
  }

  ApiState<U> copyWith({
    Uri baseApiUrl,
    String sessionId,
    int gid,
    int usedIds,
    U user,
  }) {
    return ApiState<U>(
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      sessionId: sessionId ?? this.sessionId,
      gid: gid ?? this.gid,
      usedIds: usedIds ?? this.usedIds,
      user: user ?? this.user,
    );
  }

  void toBox(Box box) {
    box.putAll({
      'baseApiUrl': baseApiUrl.toString(),
      'sessionId': sessionId,
      'gid': gid,
      'usedIds': usedIds,
      'user': user?.toMap(),
    });
  }

  factory ApiState.fromBox(Box box, ApiUserParser<U> parseUser) {
    final state = ApiState<U>(
      baseApiUrl: Uri.parse(box.get('baseApiUrl')),
      sessionId: box.get('sessionId'),
      gid: box.get('gid'),
      usedIds: box.get('usedIds'),
      user: parseUser(box.get('user')),
    );

    if (state.sessionId != null) {
      if (state.gid == null || state.usedIds == null || state.user == null) {
        // * Invalid logged in state where the session id is set but not the
        // * required params
        // ! TODO: Silent fail
        return ApiState(baseApiUrl: state.baseApiUrl);
      }
    } else {
      return ApiState(baseApiUrl: state.baseApiUrl);
    }
    return state;
  }

  factory ApiState.fromMap(
      Map<String, dynamic> map, ApiUserParser<U> parseUser) {
    if (map == null) return null;

    return ApiState<U>(
      baseApiUrl: Uri.parse(map['baseApiUrl']),
      sessionId: map['sessionId'],
      gid: map['gid'],
      usedIds: map['usedIds'],
      user: parseUser(map['user']),
    );
  }

  @override
  String toString() {
    return 'ApiState(baseApiUrl: $baseApiUrl, sessionId: $sessionId, gid: $gid, usedIds: $usedIds, user: $user)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ApiState<U> &&
        o.baseApiUrl == baseApiUrl &&
        o.sessionId == sessionId &&
        o.gid == gid &&
        o.usedIds == usedIds &&
        o.user == user;
  }

  @override
  int get hashCode {
    return baseApiUrl.hashCode ^
        sessionId.hashCode ^
        gid.hashCode ^
        usedIds.hashCode ^
        user.hashCode;
  }
}
