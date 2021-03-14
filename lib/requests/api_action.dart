import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/core/api_user.dart';
import 'package:appcore/core/datastore.dart';
import 'package:http/http.dart';

abstract class ApiAction<D extends Datastore, U extends ApiUser,
    T extends ApiCubit<D, U, T>> {
  String get name;

  dynamic get binaryData => null;

  String generateDescription(T api);

  BaseRequest createRequest(T api);

  void applyOptimisticUpdate(T api);

  void revertOptimisticUpdate(T api);

  Map<String, dynamic> toMap();
}
