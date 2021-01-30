import 'dart:convert';
import 'dart:io';

import 'package:appcore/core/api_user.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uri/uri.dart';

import 'datastore.dart';
import 'core_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'core_browser.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'core_mobile.dart';

import 'api_state.dart';

const _dataKeyTime = "__time";
const _dataKeyClearData = "__clearData";
const _metadataKeyLastSyncTime = "lastSyncTime";
const _paramKeyLastSyncTime = "lastSyncTime";
const _metadataKeyLastSyncPermissions = "lastSyncPermissions";
const _paramKeyLastSyncPermissions = "lastSyncPermissions";

const _gidShift = 10; // Must match up with the server

class ApiCubit<D extends Datastore, U extends ApiUser> extends Cubit<ApiState> {
  final Box persist;
  final D datastore;
  final BaseClient client = createHttpClient();
  final ApiUserParser<U> _parseUser;
  final String _fixedBaseApiUrl;

  ApiCubit(
    this.persist,
    this.datastore,
    this._parseUser, {
    String fixedBaseApiUrl,
  })  : this._fixedBaseApiUrl = fixedBaseApiUrl,
        super(ApiState.fromBox(persist, _parseUser)) {
          if (!datastore.isInitialized) {
            throw Exception('Datastore not initialized');
          }
        }

  bool get isSignedIn => state.sessionId != null;

  bool get canChangeApiBaseUrl => _fixedBaseApiUrl == null;

  set serverUri(Uri value) {
    emit(state.copyWith(baseApiUrl: value));
  }

  String createUrl(String path) {
    return '${state.baseApiUrl}$path';
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(state.baseApiUrl);
    builder.path += path;
    return builder;
  }

  Future<int> generateNextId() async {
    if (state.gid == null) return null;
    int nextId = state.usedIds | (state.gid << _gidShift);
    emit(state.copyWith(usedIds: this.state.usedIds + 1));
    return nextId;
  }

  Future<StreamedResponse> sendAuthenticatedRequest(BaseRequest request) {
    request.headers['Authorization'] = 'SessionId $state.sessionId';
    return client.send(request);
  }

  Future<void> signOut() async {
    await datastore.clear();
    emit(ApiState(baseApiUrl: state.baseApiUrl));
  }

  Map<String, String> createLastSyncParams({bool incremental = true}) =>
      incremental
          ? <String, String>{
              _paramKeyLastSyncTime: datastore
                  .getMetadata(_metadataKeyLastSyncTime, defaultValue: 0)
                  .toString(),
              _paramKeyLastSyncPermissions: datastore
                  .getMetadata(_metadataKeyLastSyncPermissions, defaultValue: 0)
                  .toString(),
            }
          : <String, String>{};

  Future<String> loginWithGoogle(
    String email,
    String idToken,
  ) async {
    debugPrint('[login] Google');
    if (state.sessionId != null) {
      return "Already Logged In";
    }
    if (idToken?.isEmpty ?? true) {
      return "No ID Token given for Google login";
    }
    final request =
        Request('post', Uri.parse(createUrl('/v1/login/google-id-token')));
    request.headers['Authorization'] = 'Bearer $idToken';
    return sendLoginRequest(request);
  }

  Future<String> loginWithSessionId(String sessionId) async {
    debugPrint('[login] SessionID');
    if (state.sessionId != null) {
      return "Already Logged In";
    }
    final request = Request('get', Uri.parse(createUrl('/v1/sync')));
    request.headers['Authorization'] = 'SessionId $sessionId';
    return sendLoginRequest(request);
  }

  Future<String> sendLoginRequest(Request request) async {
    debugPrint('[login] Sending request to ${request.url}');
    await datastore.clear();

    try {
      final response = await client.send(request);
      if (response.statusCode == 200) {
        await parseResponseString(await response.stream.bytesToString());
        debugPrint("[login] Success");

        return null;
      } else {
        return response.stream.bytesToString();
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        debugPrint(e.toString());
        return "Server Unreachable";
      } else {
        return e.toString();
      }
    }
  }

  Future<void> parseResponseString(String responseString) async {
    if (responseString.isNotEmpty) {
      final responseMap = json.decode(responseString) as Map<String, dynamic>;
      await parseResponseMap(responseMap);
    }
  }

  Future<bool> parseResponseMap(Map<String, dynamic> response) async {
    debugPrint('[api] Parsing response');
    if (response.containsKey('session')) {
      debugPrint('[api] Parsing session');
      final session =
          _parseSession(response['session'] as Map<String, dynamic>);
      if (session == null) return false;
      emit(state.copyWith(
        sessionId: session.sessionId,
        gid: session.gid,
        user: session.user,
      ));
    }

    if (response.containsKey('data')) {
      debugPrint('[datastore] Parsing data');
      final data = response['data'] as Map<String, dynamic>;
      if (data.containsKey(_dataKeyClearData) && data[_dataKeyClearData]) {
        await datastore.clear();
        print("Clearing Data");
      }
      await datastore.parseData(data);

      debugPrint('[datastore] Data Parsed');
      if (data.containsKey(_dataKeyTime)) {
        datastore.putMetadata(
            _metadataKeyLastSyncTime, data[_dataKeyTime] as int);
        datastore.putMetadata(
            _metadataKeyLastSyncPermissions, state.user.permissions);
      }
    }
    if (response.containsKey('debug')) {
      debugPrint(response['debug'].toString());
    }
    debugPrint('[api] Response parsed');
    return true;
  }

  ApiState _parseSession(Map<String, dynamic> session) {
    final state = ApiState.fromMap(session, _parseUser);
    if (state.gid == null || state.sessionId == null || state.user == null)
      return null;
    return state;
  }

  void debugPrintSessionDetails() {
    debugPrint('[login]  server url: ${state.baseApiUrl}');
    debugPrint('[login]   sessionId: ${state.sessionId}');
    debugPrint('[login]         gid: ${state.gid}');
    debugPrint('[login]    gid base: ${state.gid << _gidShift}');
    debugPrint('[login]    used ids: ${state.usedIds}');
    debugPrint(
        '[login]    next gid: ${state.usedIds | (state.gid << _gidShift)}');
    debugPrint('[login]        user: ${state.user}');
  }
}
