import 'dart:async';

import 'package:hive/hive.dart';
import 'package:http/http.dart';

import '../core/api_request.dart';
import '../core/api_client.dart';
import '../core/account.dart';

abstract class ApiAction<A extends Account> extends ApiRequest with HiveObjectMixin {
  @override
  int get key => super.key;

  String get name;

  dynamic get binaryData => null;

  @override
  dynamic get tag => null;

  String generateDescription(A account);

  String generatePayloadDetails();

  @override
  BaseRequest createRequest(ApiClient api);

  FutureOr<void> applyOptimisticUpdate(A account);

  FutureOr<void> revertOptimisticUpdate(A account);

  Map<String, dynamic> toMap();
}
