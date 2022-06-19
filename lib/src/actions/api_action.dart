part of 'actions.dart';

abstract class ApiAction<D extends Domain> with HiveObjectMixin {
  int get id => super.key;

  String get name;

  dynamic get binaryData => null;

  String generateDescription(D api);

  String generatePayloadDetails();

  BaseRequest createRequest(ApiClient api);

  FutureOr<void> applyOptimisticUpdate(D api);

  FutureOr<void> revertOptimisticUpdate(D api);

  Map<String, dynamic> toMap();
}
