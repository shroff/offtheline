part of 'actions.dart';

const _contentType = 'application/json';

mixin JsonApiAction<S extends ApiSession, T extends ApiCubit<S>>
    on ApiAction<T> {
  String get method;
  String get endpoint;

  @override
  BaseRequest createRequest(T api) {
    final request = Request(method, api.createUriBuilder(endpoint).build());
    request.headers['content-type'] = _contentType;
    final body = generateRequestBody(api);
    if (body != null) {
      request.body = json.encode(generateRequestBody(api));
    }

    return request;
  }

  @override
  String generatePayloadDetails(T api) => json.encode(generateRequestBody(api));

  Map<String, dynamic>? generateRequestBody(T api);
}
