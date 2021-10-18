part of 'actions.dart';

const _contentType = 'application/json';

mixin JsonApiAction<T extends ApiCubit> on ApiAction<T> {
  String get method;
  String get endpoint;

  @override
  BaseRequest createRequest(DomainApi<T> api) {
    final request = Request(method, api.createUriBuilder(endpoint).build());
    request.headers['content-type'] = _contentType;
    final body = generateRequestBody(api);
    if (body != null) {
      request.body = json.encode(generateRequestBody(api));
    }

    return request;
  }

  @override
  String generatePayloadDetails(DomainApi<T> api) =>
      json.encode(generateRequestBody(api));

  Map<String, dynamic>? generateRequestBody(DomainApi<T> api);
}
