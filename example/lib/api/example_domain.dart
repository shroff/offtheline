import 'dart:async';
import 'dart:convert';

import 'package:example/api/example_datastore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

import 'example_id_allocator.dart';
import 'user_agent.dart';

const _persistKeyAuthToken = 'authToken';
const _persistKeyUserName = 'userName';
const _persistKeyUserDisplayName = 'userDisplayName';
const _persistKeyDomainDisplayName = 'domainDisplayName';
const _persistKeyUseFakeDispatcher = 'useFakeDispatcher';

class ExampleDomain extends Domain<Map<String, dynamic>> with ChangeNotifier {
  final datastore = ExampleDatastore();
  final idAllocator = ExampleIdAllocator();

  ExampleDomain({required super.id, required super.api, required super.clear});

  String? get _authToken => getPersisted(_persistKeyAuthToken);
  set _authToken(String? value) {
    persist(_persistKeyAuthToken, value);
    api.setHeader('Authorization', 'Bearer $value');
  }

  String get userName => getPersisted(_persistKeyUserName);
  set userName(String value) {
    persist(_persistKeyUserName, value);
    notifyListeners();
  }

  String get userDisplayName => getPersisted(_persistKeyUserDisplayName);
  set userDisplayName(String value) {
    persist(_persistKeyUserDisplayName, value);
    notifyListeners();
  }

  String get domainDisplayName => getPersisted(_persistKeyDomainDisplayName);
  set domainDisplayName(String value) {
    persist(_persistKeyDomainDisplayName, value);
    notifyListeners();
  }

  static Future<ExampleDomain> restore(String id) {
    return open(id, clear: false);
  }

  static Future<ExampleDomain> open(String id, {bool clear = true}) async {
    final api = ApiClient(
        transformResponse: (response) =>
            jsonDecode(response) as Map<String, dynamic>?);
    final domain = ExampleDomain(id: id, api: api, clear: clear);
    await domain.initialized;

    if (domain.getPersisted(_persistKeyUseFakeDispatcher) == true) {
      domain.api.dispatcher = _FakeDispatcher();
    }
    domain.api.setHeader('User-Agent', userAgent);

    return domain;
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
    _setAuthorizationHeader(_authToken);
    await registerHooks(datastore);
    await registerHooks(idAllocator);
  }

  static Future<ExampleDomain> createFromLoginResponse(
    Map<String, dynamic> response, {
    bool useFakeDispatcher = false,
  }) async {
    final sessionMap = (response['session'] as Map).cast<String, dynamic>();
    final dataMap = (response['data'] as Map).cast<String, dynamic>();
    final configMap = (response['config'] as Map).cast<String, dynamic>();

    final domain =
        await ExampleDomain.open(sessionMap['domain_id'], clear: true);

    domain.userName = sessionMap['user_name'];
    domain.userDisplayName = sessionMap['user_display_name'];
    domain.domainDisplayName = sessionMap['domain_display_name'];

    domain._authToken = sessionMap['auth_token'];
    domain.idAllocator.idBlockSize = configMap['id_block_size'];
    domain.api.processResponse(dataMap);

    if (useFakeDispatcher) {
      domain.api.dispatcher = _FakeDispatcher();
      domain.persist(_persistKeyUseFakeDispatcher, true);
    }

    return domain;
  }

  void _setAuthorizationHeader(String? token) {
    api.setHeader('Authorization', token == null ? null : 'Bearer $token');
  }

  Future<int> generateId() {
    return idAllocator.generateId();
  }
}

class _FakeDispatcher with Dispatcher {
  @override
  Response dispatch(BaseRequest request) => Response.bytes([], 200);
}
