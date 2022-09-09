import 'dart:convert';

import 'package:http/http.dart';
import 'package:uri/uri.dart';

import 'api_action.dart';

const _contentType = 'application/json';

mixin JsonApiAction<Datastore> on ApiAction<Datastore> {
  String get method;
  String get endpoint;

  @override
  BaseRequest createRequest(UriBuilder uriBuilder) {
    uriBuilder.path += endpoint;
    final request = Request(method, uriBuilder.build());
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
