import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart';

import 'api_action.dart';
import '../core/api_client.dart';
import '../core/account.dart';

mixin FileUploadApiAction<T, R extends ApiResponse<T>, A extends Account<T, R>>
    on ApiAction<T, R, A> {
  @override
  dynamic get binaryData => fileContents;

  String get method;
  String get endpoint;

  String get fileFieldName;
  String get fileName;
  Uint8List get fileContents;

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder(endpoint).build();
    final request = MultipartRequest(method, uri);
    request.fields.addAll(generateFormFields());
    final filePart = MultipartFile.fromBytes(
      fileFieldName,
      fileContents,
      filename: fileName,
    );
    request.files.add(filePart);

    return request;
  }

  @override
  String generatePayloadDetails() => json.encode({
        'file': {
          'fieldName': fileFieldName,
          'name': fileName,
          'size': fileContents.length,
        },
        'fields': generateFormFields(),
      });

  Map<String, String> generateFormFields();
}
