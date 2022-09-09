import 'dart:async';

import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

abstract class ApiAction<Datastore> with HiveObjectMixin {
  @override
  int get key => super.key;

  String get name;

  dynamic get binaryData => null;

  dynamic get tag => null;

  String generateDescription(Datastore datastore);

  String generatePayloadDetails();

  BaseRequest createRequest(UriBuilder uriBuilder);

  FutureOr<void> applyOptimisticUpdate(Datastore datastore);

  FutureOr<void> revertOptimisticUpdate(Datastore datastore);

  Map<String, dynamic> toMap();
}
