import 'dart:async';

import 'package:hive/hive.dart';
import 'package:http/http.dart';

import '../core/api_client.dart';
import '../core/account.dart';

abstract class ApiAction<A extends Account> with HiveObjectMixin {
  @override
  int get key => super.key;

  String get name;

  dynamic get binaryData => null;

  dynamic get tag => null;

  String generateDescription(A account);

  String generatePayloadDetails();

  BaseRequest createRequest(ApiClient api);

  FutureOr<void> applyOptimisticUpdate(A account);

  FutureOr<void> revertOptimisticUpdate(A account);

  Map<String, dynamic> toMap();
}
