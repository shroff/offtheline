import 'dart:convert';

import 'package:http/http.dart';

import 'api_action.dart';
import '../core/api_client.dart';
import '../core/domain.dart';

class UnknownAction<A extends Account> extends ApiAction<A> {
  @override
  final String name;
  final Map<String, dynamic> props;
  @override
  final dynamic binaryData;

  UnknownAction({
    required this.name,
    required this.props,
    required this.binaryData,
  });

  @override
  String generateDescription(A account) {
    return 'Nop Action';
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
    return other is UnknownAction && other.props == props;
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
        'props': props,
      });
}
