library apiclient;

import 'dart:async';
import 'dart:io';

import 'package:appcore/appcore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

part 'action_queue.dart';

typedef ResponseProcessor<R> = FutureOr<void> Function(R response);

abstract class ApiClient<R, E> with ChangeNotifier {
  final ongoingOperations = ValueNotifier<int>(0);
  final Client _client = Client();
  final Uri _apiBase;
  final List<ResponseProcessor<R>> _responseProcessors = [];
  @protected
  final String name;
  late final ApiActionQueue actionQueue = ApiActionQueue(this);

  List<Future> _initializers = [];
  final Completer _initializationCompleter = Completer();
  Future<void> get initialized => _initializationCompleter.future;

  Map<String, String> get requestHeaders;
  bool _closed = false;
  @protected
  bool get closed => _closed;

  ApiClient({
    required Uri apiBaseUrl,
    required this.name,
  })  : this._apiBase = apiBaseUrl,
        super() {
    _initializers.add(actionQueue.initialize(name));
    Future(() => Future.wait(_initializers)
        .then((value) => _initializationCompleter.complete()));
  }

  @protected
  @nonVirtual
  void addInitializer(Future initializer) {
    _initializers.add(initializer);
  }

  @nonVirtual
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

  FutureOr<void> putMetadata<E>(String key, E value);

  void addResponseProcessor(ResponseProcessor<R> processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor<R> processor) {
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
      actionQueue._sendNextAction();
      // Show request result
      if (response.statusCode == 200) {
        await parseResponseString(responseString);
        return null;
      } else {
        return processErrorResponse(
            await transformErrorResponse(responseString));
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
    if (responseString.isNotEmpty) {
      final response = await transformResponse(responseString);
      processResponse(response);
    }
  }

  @nonVirtual
  Future<void> processResponse(R response) async {
    final completer = Completer<void>();
    try {
      debugPrint('[api] Parsing response');
      await processResponseInternal(response);
      for (final processResponse in _responseProcessors) {
        await processResponse(response);
      }
    } finally {
      completer.complete();
      debugPrint('[api] Response parsed');
    }
  }

  FutureOr<R> transformResponse(String resopnse);

  @protected
  FutureOr<E> transformErrorResponse(String resopnse);

  @protected
  FutureOr<void> processResponseInternal(R response);

  @protected
  FutureOr<String> processErrorResponse(E errorResponse) =>
      errorResponse.toString();
}
