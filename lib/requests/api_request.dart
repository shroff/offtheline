import 'package:hive/hive.dart';
import 'package:http/http.dart';

abstract class ApiRequest extends HiveObject {
  String get endpoint;
  String get description;
  String get method;

  Future<BaseRequest> createRequest(Uri uri);

  String get dataString; 
}
