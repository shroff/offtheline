part of 'actions.dart';

abstract class ApiAction<T extends ApiCubit> {
  String get name;

  dynamic get binaryData => null;

  String generateDescription(DomainApi<T> api);

  String generatePayloadDetails(DomainApi<T> api);

  BaseRequest createRequest(DomainApi<T> api);

  FutureOr<void> applyOptimisticUpdate(DomainApi<T> api);

  FutureOr<void> revertOptimisticUpdate(DomainApi<T> api);

  Map<String, dynamic> toMap();
}
