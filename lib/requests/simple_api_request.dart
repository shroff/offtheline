import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart';

import 'api_request.dart';

part 'simple_api_request.g.dart';

@HiveType(typeId: 10)
class SimpleApiRequest extends ApiRequest {
  @HiveField(0)
  final String method;
  @HiveField(1)
  final String endpoint;
  @HiveField(2)
  final String description;

  @HiveField(3)
  final String contentType;
  @HiveField(4)
  final dynamic body;

  SimpleApiRequest(this.method, this.endpoint, this.description,
      {this.body, this.contentType});

  SimpleApiRequest.json(
      String method, String endpoint, String description, dynamic body)
      : this(method, endpoint, description,
            body: body, contentType: 'application/json');

  String toString() =>
      'ApiSimpleRequest(endpoint: $endpoint, description: $description, content-type: $contentType, body: $body)';

  @override
  Future<BaseRequest> createRequest(Uri uri) async {
    final request = Request(method, uri);
    if (contentType != null) {
      request.headers['content-type'] = contentType;
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    return request;
  }
}