import 'dart:convert';
import 'dart:typed_data';

import 'package:appcore/core/api.dart';
import 'package:appcore/requests/requests.dart';
import 'package:http/http.dart';

mixin FileUploadApiAction<
    I,
    D extends Datastore<I, D, S, T>,
    S extends ApiSession,
    T extends ApiCubit<I, D, S, T>> on ApiAction<I, D, S, T> {
  @override
  dynamic get binaryData => fileContents;

  String get method;
  String get endpoint;

  String get fileFieldName;
  String get fileName;
  Uint8List get fileContents;

  @override
  BaseRequest createRequest(ApiCubit<I, D, S, T> api) {
    final uri = api.createUriBuilder(endpoint).build();
    final request = MultipartRequest(method, uri);
    request.fields.addAll(generateFormFields(api));
    final filePart = MultipartFile.fromBytes(
      fileFieldName,
      fileContents,
      filename: fileName,
    );
    request.files.add(filePart);

    return request;
  }

  @override
  String generatePayloadDetails(ApiCubit<I, D, S, T> api) => json.encode({
        'file': {
          'fieldName': fileFieldName,
          'name': fileName,
          'size': fileContents.length,
        },
        'fields': generateFormFields(api),
      });

  Map<String, String> generateFormFields(ApiCubit<I, D, S, T> api);
}
