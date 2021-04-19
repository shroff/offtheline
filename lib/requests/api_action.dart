import 'dart:async';

import 'package:appcore/core/api.dart';
import 'package:http/http.dart';

abstract class ApiAction<T extends ApiCubit> {
  String get name;

  dynamic get binaryData => null;

  String generateDescription(T api);

  String generatePayloadDetails(T api);

  BaseRequest createRequest(T api);

  FutureOr<void> applyOptimisticUpdate(T api);

  FutureOr<void> revertOptimisticUpdate(T api);

  Map<String, dynamic> toMap();
}
