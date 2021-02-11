import 'dart:convert';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/requests/requests.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

const _contentType = 'application/json';

abstract class JsonApiAction<T extends ApiCubit> extends ApiAction<T> {
  @HiveField(-1)
  final String method;
  @HiveField(-2)
  final String endpoint;

  JsonApiAction(
    this.method,
    this.endpoint,
  );

  @override
  BaseRequest createRequest(T api) {
    final request = Request(method, api.createUriBuilder(endpoint).build());
    request.headers['content-type'] = _contentType;
    request.body = json.encode(generateRequestBody(api));

    return request;
  }

  Map<String, dynamic> generateRequestBody(T api);
}
