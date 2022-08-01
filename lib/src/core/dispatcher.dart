import 'dart:async';

import 'package:http/http.dart';

abstract class Dispatcher {
  FutureOr<Response> dispatch(BaseRequest request);
}

class HttpClientDispatcher with Dispatcher {
  final Client _client = Client();

  @override
  Future<Response> dispatch(BaseRequest request) async {
    return Response.fromStream(await _client.send(request));
  }
}
