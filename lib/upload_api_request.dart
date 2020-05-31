import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'api_request.dart';

part 'upload_api_request.g.dart';

@HiveType(typeId: 11)
class UploadApiRequest extends ApiRequest {
  @HiveField(0)
  final String method;
  @HiveField(1)
  final String endpoint;
  @HiveField(2)
  final String description;

  @HiveField(3)
  final Uint8List contents;
  @HiveField(4)
  final String fileFieldName;
  @HiveField(5)
  final String fileName;
  @HiveField(6)
  final Map<String, String> formFields;

  UploadApiRequest(
    this.endpoint,
    this.description,
    this.contents,
    this.fileName, {
    this.method = 'post',
    this.fileFieldName = 'file',
    this.formFields,
  });

  String toString() =>
      'UploadApiRequest(endpoint: $endpoint, description: $description, fields: $formFields, fileName: $fileName)';

  @override
  Future<BaseRequest> createRequest(Uri uri) async {
    final request = MultipartRequest(method, uri);
    request.fields.addAll(formFields ?? {});
    final filePart = MultipartFile.fromBytes(
      fileFieldName,
      contents,
      filename: fileName,
    );
    request.files.add(filePart);

    return request;
  }
}
