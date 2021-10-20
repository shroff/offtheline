part of 'actions.dart';

const _contentType = 'application/json';

mixin JsonApiAction<A extends ApiClient> on ApiAction<A> {
  String get method;
  String get endpoint;

  @override
  BaseRequest createRequest(A api) {
    final request = Request(method, api.createUriBuilder(endpoint).build());
    request.headers['content-type'] = _contentType;
    final body = generateRequestBody(api);
    if (body != null) {
      request.body = json.encode(generateRequestBody(api));
    }

    return request;
  }

  @override
  String generatePayloadDetails(A api) => json.encode(generateRequestBody(api));

  Map<String, dynamic>? generateRequestBody(A api);
}
