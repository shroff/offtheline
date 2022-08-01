import 'api_client.dart';
import 'domain.dart';

const _persistKeyAuthorization = 'authorization';

class AuthHeaderApiClient<R> extends ApiClient<R> {
  AuthHeaderApiClient({required ResponseTransformer<R> transformResponse})
      : super(transformResponse: transformResponse);

  @override
  Future<void> initialize(Domain<R> domain) async {
    await super.initialize(domain);
    setHeader('Authorization', domain.getPersisted(_persistKeyAuthorization));
  }

  set authorization(String? authorization) {
    domain.persist(_persistKeyAuthorization, authorization);
    setHeader('Authorization', authorization);
  }
}
