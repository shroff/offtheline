import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:uri/uri.dart';

import 'api_action.dart';

mixin FileUploadApiAction<Datastore> on ApiAction<Datastore> {
  @override
  dynamic get binaryData => fileContents;

  String get method;
  String get endpoint;

  String get fileFieldName;
  String get fileName;
  Uint8List get fileContents;

  @override
  BaseRequest createRequest(UriBuilder uriBuilder) {
    uriBuilder.path += endpoint;
    final request = MultipartRequest(method, uriBuilder.build());
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
