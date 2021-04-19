import 'dart:async';

import 'package:appcore/core/api.dart';
import 'package:http/http.dart';

abstract class ApiAction<D extends Datastore<D, S, T>, S extends ApiSession,
    T extends ApiCubit<D, S, T>> {
  String get name;

  dynamic get binaryData => null;

  String generateDescription(ApiCubit<D, S, T> api);

  String generatePayloadDetails(ApiCubit<D, S, T> api);

  BaseRequest createRequest(ApiCubit<D, S, T> api);

  FutureOr<void> applyOptimisticUpdate(ApiCubit<D, S, T> api);

  FutureOr<void> revertOptimisticUpdate(ApiCubit<D, S, T> api);

  Map<String, dynamic> toMap();
}
