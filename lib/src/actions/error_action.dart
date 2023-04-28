import 'dart:convert';

import 'package:http/http.dart';

import 'api_action.dart';
import '../core/api_client.dart';
import '../core/account.dart';

class ErrorAction<A extends Account> extends ApiAction<A> {
  @override
  final String name;
  final String error;
  final Map<String, dynamic> props;
  @override
  final dynamic binaryData;

  ErrorAction({
    required this.name,
    required this.error,
    required this.props,
    required this.binaryData,
  });

  @override
  String generateDescription(A account) {
    return 'Error Action ($name): $error';
  }

  @override
  void applyOptimisticUpdate(A account) {}

  @override
  void revertOptimisticUpdate(A account) {}

  @override
  Map<String, dynamic> toMap() => props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorAction && other.props == props;
  }

  @override
  int get hashCode {
    return props.hashCode;
  }

  @override
  BaseRequest createRequest(ApiClient api) {
    return Request('nop', Uri());
  }

  @override
  String generatePayloadDetails() => json.encode({
        'name': name,
        'error': error,
        'props': props,
      });
}
