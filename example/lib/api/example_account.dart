import 'dart:async';
import 'dart:convert';

import 'package:example/api/example_datastore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'api.dart';
import 'example_id_allocator.dart';

const _persistKeyAuthToken = 'authToken';
const _persistKeyUserName = 'userName';
const _persistKeyUserDisplayName = 'userDisplayName';
const _persistKeyAccuontProviderName = 'accountProviderName';
const _persistKeyUseFakeDispatcher = 'useFakeDispatcher';

class ExampleAccount extends Account<Map<String, dynamic>> with ChangeNotifier {
  final datastore = ExampleDatastore();
  final idAllocator = ExampleIdAllocator();

  ExampleAccount([String? id])
      : super(
          id: id,
          api: ApiClient(
              transformResponse: (response) =>
                  jsonDecode(response) as Map<String, dynamic>?),
        );

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

  String get providerName => getPersisted(_persistKeyAccuontProviderName);
  set providerName(String value) {
    persist(_persistKeyAccuontProviderName, value);
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
    _setAuthorizationHeader(_authToken);
    await registerListener(datastore);
    await registerListener(idAllocator);

    api.setHeader('User-Agent', Api.userAgent);
    if (getPersisted(_persistKeyUseFakeDispatcher) == true) {
      api.dispatcher = _FakeDispatcher();
    }
  }

  static Future<ExampleAccount> createFromLoginResponse(
    Map<String, dynamic> response, {
    bool useFakeDispatcher = false,
  }) async {
    final sessionMap = (response['session'] as Map).cast<String, dynamic>();
    final dataMap = (response['data'] as Map).cast<String, dynamic>();
    final configMap = (response['config'] as Map).cast<String, dynamic>();

    final account = ExampleAccount();
    await account.initialized;

    account.userName = sessionMap['user_name'];
    account.userDisplayName = sessionMap['user_display_name'];
    account.providerName = sessionMap['account_provider_name'];

    account._authToken = sessionMap['auth_token'];
    account.idAllocator.idBlockSize = configMap['id_block_size'];
    account.api.processResponse(dataMap);

    if (useFakeDispatcher) {
      account.api.dispatcher = _FakeDispatcher();
      account.persist(_persistKeyUseFakeDispatcher, true);
    }

    return account;
  }

  void _setAuthorizationHeader(String? token) {
    api.setHeader('Authorization', token == null ? null : 'Bearer $token');
  }

  Future<int> generateId() {
    return idAllocator.generateId();
  }
}

class _FakeDispatcher with Dispatcher {
  final response = "{}".codeUnits;
  @override
  Response dispatch(BaseRequest request) => Response.bytes(response, 200);
}
