part of 'actions.dart';

mixin FileUploadApiAction<T extends DomainApi> on ApiAction<T> {
  @override
  dynamic get binaryData => fileContents;

  String get method;
  String get endpoint;

  String get fileFieldName;
  String get fileName;
  Uint8List get fileContents;

  @override
  BaseRequest createRequest(T api) {
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
  String generatePayloadDetails(T api) => json.encode({
        'file': {
          'fieldName': fileFieldName,
          'name': fileName,
          'size': fileContents.length,
        },
        'fields': generateFormFields(api),
      });

  Map<String, String> generateFormFields(T api);
}
