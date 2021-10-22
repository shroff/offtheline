part of 'actions.dart';

const _contentType = 'application/json';

mixin JsonApiAction<D extends Domain> on ApiAction<D> {
  String get method;
  String get endpoint;

  @override
  BaseRequest createRequest(ApiClient api) {
    final request = Request(method, api.createUriBuilder(endpoint).build());
    request.headers['content-type'] = _contentType;
    final body = generateRequestBody();
    if (body != null) {
      request.body = json.encode(generateRequestBody());
    }

    return request;
  }

  @override
  String generatePayloadDetails() => json.encode(generateRequestBody());

  Map<String, dynamic>? generateRequestBody();
}
