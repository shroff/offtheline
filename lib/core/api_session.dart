part of 'api.dart';

abstract class ApiSession {
  String get sessionId;

  Map<String, dynamic> toMap();

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '${this.runtimeType}(sessionId: $sessionId)';
  }
}
