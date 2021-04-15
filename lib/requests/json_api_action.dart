import 'dart:convert';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/core/datastore.dart';
import 'package:appcore/requests/requests.dart';
import 'package:http/http.dart';

const _contentType = 'application/json';

mixin JsonApiAction<I, D extends Datastore<I, D, S, T>, S extends ApiSession,
    T extends ApiCubit<I, D, S, T>> on ApiAction<I, D, S, T> {
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
