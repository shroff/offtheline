import 'api_client.dart';
import 'domain.dart';

const _persistKeySessionId = "sessionID";

class SessionIdAuthHeaderApiClient<R> extends ApiClient<R> {
  SessionIdAuthHeaderApiClient(
      {required ResponseTransformer<R> transformResponse})
      : super(transformResponse: transformResponse);

  @override
  Future<void> initialize(Domain<R> domain) async {
    await super.initialize(domain);
    setHeader('Authorization',
        "SessionId ${domain.getPersisted(_persistKeySessionId)}");
  }

  @override
  bool get valid =>
      super.valid && domain.getPersisted(_persistKeySessionId) != null;

  String? get sessionId => domain.getPersisted(_persistKeySessionId);
  set sessionId(String? value) {
    domain.persist(_persistKeySessionId, value);
    setHeader('Authorization', 'SessionId $value');
  }
}
