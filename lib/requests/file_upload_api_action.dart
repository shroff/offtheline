import 'dart:typed_data';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/core/api_user.dart';
import 'package:appcore/core/datastore.dart';
import 'package:appcore/requests/requests.dart';
import 'package:http/http.dart';

mixin FileUploadApiAction<D extends Datastore, U extends ApiUser,
    T extends ApiCubit<D, U, T>> on ApiAction<D, U, T> {
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
    request.fields.addAll(generateFormFields(api) ?? {});
    final filePart = MultipartFile.fromBytes(
      fileFieldName,
      fileContents,
      filename: fileName,
    );
    request.files.add(filePart);

    return request;
  }

  Map<String, String> generateFormFields(T api);
}
