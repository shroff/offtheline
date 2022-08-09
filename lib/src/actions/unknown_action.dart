import 'dart:convert';

import 'package:http/http.dart';

import 'api_action.dart';
import '../core/api_client.dart';
import '../core/domain.dart';

class UnknownAction<D extends Domain> extends ApiAction<D> {
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
  String generateDescription(D domain) {
    return 'Nop Action';
  }

  @override
  void applyOptimisticUpdate(D domain) {}

  @override
  void revertOptimisticUpdate(D domain) {}

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
