part of 'actions.dart';

abstract class ApiAction<A extends ApiClient> {
  String get name;

  dynamic get binaryData => null;

  String generateDescription(A api);

  String generatePayloadDetails(A api);

  BaseRequest createRequest(A api);

  FutureOr<void> applyOptimisticUpdate(A api);

  FutureOr<void> revertOptimisticUpdate(A api);

  Map<String, dynamic> toMap();
}
