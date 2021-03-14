import 'dart:convert';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/core/api_user.dart';
import 'package:appcore/core/datastore.dart';
import 'package:appcore/requests/requests.dart';
import 'package:http/http.dart';

const _contentType = 'application/json';

abstract class JsonApiAction<D extends Datastore, U extends ApiUser,
    T extends ApiCubit<D, U, T>> extends ApiAction<D, U, T> {
  String get method;
  String get endpoint;

  @override
  BaseRequest createRequest(T api) {
    final request = Request(method, api.createUriBuilder(endpoint).build());
    request.headers['content-type'] = _contentType;
    request.body = json.encode(generateRequestBody(api));

    return request;
  }

  Map<String, dynamic> generateRequestBody(T api);
}
