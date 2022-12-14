import 'dart:convert';

import 'package:http/http.dart';

import 'api_action.dart';
import '../core/api_client.dart';
import '../core/account.dart';

const _contentType = 'application/json';

mixin JsonApiAction<A extends Account> on ApiAction<A> {
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
