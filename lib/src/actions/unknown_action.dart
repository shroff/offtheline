import 'dart:convert';

import 'package:http/http.dart';

import 'api_action.dart';
import '../core/api_client.dart';
import '../core/domain.dart';

class UnknownAction extends ApiAction {
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
  String generateDescription(Domain domain) {
    return 'Nop Action';
  }

  @override
  void applyOptimisticUpdate(Domain domain) {}

  @override
  void revertOptimisticUpdate(Domain domain) {}

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
