library apiclient;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appcore/appcore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

part 'action_queue.dart';

typedef ResponseProcessor = FutureOr<void> Function(
    Map<String, dynamic> response);

abstract class ApiClient with ChangeNotifier {
  final ongoingOperations = ValueNotifier<int>(0);
  final Client _client = Client();
  final Uri _apiBase;
  final List<ResponseProcessor> _responseProcessors = [];
  @protected
  final String name;
  late final ApiActionQueue actionQueue = ApiActionQueue(this);

  Map<String, String> get requestHeaders;
  bool _closed = false;
  @protected
  bool get closed => _closed;

  ApiClient({
    required Uri apiBaseUrl,
    required this.name,
  })  : this._apiBase = apiBaseUrl,
        super() {
    initialize();
  }

  @mustCallSuper
  Future<void> initialize() async {
    actionQueue.initialize(name);
  }

  void registerOngoingOperation(Future future) {
    ongoingOperations.value = ongoingOperations.value + 1;
    future
        .then((value) => ongoingOperations.value = ongoingOperations.value - 1);
  }

  @nonVirtual
  Future<void> logout() async {
    debugPrint('[api] Logging Out');

    if (closed) return;
    _closed = true;

    actionQueue.close();

    // Wait for pending operations
    if (ongoingOperations.value != 0) {
      final completer = Completer();
      final callback = () {
        if (ongoingOperations.value == 0) {
          completer.complete();
        }
      };
      ongoingOperations.addListener(callback);
      await completer.future;
      ongoingOperations.removeListener(callback);
    }

    await clear();
  }

  @protected
  @mustCallSuper
  Future<void> clear();

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(_apiBase);
    builder.path += path;
    return builder;
  }

  E? getMetadata<E>(String key, {E? defaultValue});

  Future<void> putMetadata<E>(String key, E value);

  void addResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.remove(processor);
  }

  Future<String?> sendRequest(BaseRequest request) async {
    if (closed) return "Closed";
    final completer = Completer();
    registerOngoingOperation(completer.future);
    try {
      debugPrint('[api] Sending request to ${request.url}');
      request.headers.addAll(requestHeaders);
      final response = await _client.send(request);

      final responseString = await response.stream.bytesToString();
      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(responseString);
        return null;
      } else {
        return processErrorResponse(responseString);
      }
    } on SocketException {
      return "Server Unreachable";
    } catch (e) {
      return e.toString();
    } finally {
      completer.complete();
    }
  }

  Future<void> addAction(ApiAction action) async {
    return actionQueue.addAction(action);
  }

  Future<void> parseResponseString(String responseString) async {
    final completer = Completer<void>();
    try {
      debugPrint('[api] Parsing response');
      if (responseString.isNotEmpty) {
        final responseMap = json.decode(responseString) as Map<String, dynamic>;
        await processResponse(responseMap);
        for (final processResponse in _responseProcessors) {
          await processResponse(responseMap);
        }
        actionQueue._sendNextAction();
      }
    } finally {
      completer.complete();
      debugPrint('[api] Response parsed');
    }
  }

  @protected
  FutureOr<void> processResponse(Map<String, dynamic> responseMap);

  @protected
  FutureOr<String> processErrorResponse(String errorString) => errorString;
}
