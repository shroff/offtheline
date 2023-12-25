import 'package:http/http.dart';

import 'api_client.dart';

abstract class ApiRequest {
  dynamic get tag => null;

  BaseRequest createRequest(ApiClient api);
}
