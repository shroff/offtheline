import 'dart:async';

import 'package:hive/hive.dart';
import 'package:http/http.dart';

import '../core/api_client.dart';
import '../core/domain.dart';

abstract class ApiAction<D extends Domain> with HiveObjectMixin {
  int get id => super.key;

  String get name;

  dynamic get binaryData => null;

  dynamic get tag => null;

  String generateDescription(D domain);

  String generatePayloadDetails();

  BaseRequest createRequest(ApiClient api);

  FutureOr<void> applyOptimisticUpdate(D domain);

  FutureOr<void> revertOptimisticUpdate(D domain);

  Map<String, dynamic> toMap();
}
