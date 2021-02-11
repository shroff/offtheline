import 'package:appcore/core/api_cubit.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

abstract class ApiAction<T extends ApiCubit> extends HiveObject {
  String generateDescription(T api);

  BaseRequest createRequest(T api);

  void applyOptimisticUpdate(T api);

  void revertOptimisticUpdate(T api);
}
