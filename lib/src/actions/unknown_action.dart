import 'dart:convert';

import 'package:http/http.dart';
import 'package:uri/uri.dart';

import 'api_action.dart';
import '../core/api_client.dart';

class UnknownAction<Datastore> extends ApiAction<Datastore> {
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
  String generateDescription(Datastore datastore) {
    return 'Nop Action';
  }

  @override
  void applyOptimisticUpdate(Datastore datastore) {}

  @override
  void revertOptimisticUpdate(Datastore datastore) {}

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
  BaseRequest createRequest(UriBuilder uriBuilder) {
    return Request('nop', uriBuilder.build());
  }

  @override
  String generatePayloadDetails() => json.encode({
        'name': name,
        'props': props,
      });
}
