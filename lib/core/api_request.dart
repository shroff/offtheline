import 'package:http/http.dart';

abstract class ApiRequest {
  String get endpoint;
  String get description;
  String get method;

  Future<BaseRequest> createRequest(Uri uri);
}
