import 'package:appcore/core/api_cubit.dart';
import 'package:http/http.dart';

abstract class ApiAction<T extends ApiCubit> {
  String get name => runtimeType.toString();

  String generateDescription(T api);

  BaseRequest createRequest(T api);

  void applyOptimisticUpdate(T api);

  void revertOptimisticUpdate(T api);

  Map<String, dynamic> toMap();
}
