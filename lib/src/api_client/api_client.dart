library apiclient;

import 'dart:async';
import 'dart:io';

import 'package:appcore/appcore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

part 'action_queue.dart';
part 'domain.dart';
part 'domain_hooks.dart';

const _metadataKeyApiBaseUrl = "apiBaseUrl";

typedef ResponseTransformer<R> = FutureOr<R> Function(String);
typedef ResponseProcessor<R> = FutureOr<void> Function(R response);

class ApiClient<R> with DomainHooks<R> {
  final Client _client = Client();
  final ResponseTransformer<R> transformResponse;
  final List<ResponseProcessor<R>> _responseProcessors = [];

  Uri get apiBaseUrl => _domain.getMetadata(_metadataKeyApiBaseUrl);
  set apiBaseUrl(Uri url) => _domain.putMetadata(_metadataKeyApiBaseUrl, url);

  ApiClient({
    required this.transformResponse,
  });

  Map<String, String> _requestHeaders = Map.unmodifiable({});
  Map<String, String> get requestHeaders => _requestHeaders;
  void setHeader(String key, String? value) {
    final headers = Map.from(_requestHeaders);
    if (value == null) {
      headers.remove(key);
    } else {
      headers[key] = value;
    }
    _requestHeaders = Map.unmodifiable(headers);
  }

  set userAgent(String? userAgent) {
    setHeader('User-Agent', userAgent);
  }

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(apiBaseUrl);
    builder.path += path;
    return builder;
  }

  void addResponseProcessor(ResponseProcessor<R> processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor<R> processor) {
    _responseProcessors.remove(processor);
  }

  Future<String?> sendRequest(BaseRequest request) async {
    if (_closed) return "Client Closed";
    final completer = Completer();
    _domain.registerOngoingOperation(completer.future);
    try {
      debugPrint('[api] Sending request to ${request.url}');
      request.headers.addAll(requestHeaders);
      final response = await _client.send(request);

      final responseString = await response.stream.bytesToString();
      // Show request result
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await processResponseString(responseString);
        return null;
      } else {
        return responseString;
      }
    } on SocketException {
      return "Server Unreachable";
    } catch (e) {
      return e.toString();
    } finally {
      completer.complete();
    }
  }

  Future<void> processResponseString(String responseString) async {
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
      for (final processResponse in _responseProcessors) {
        await processResponse(response);
      }
    } finally {
      completer.complete();
      debugPrint('[api] Response parsed');
    }
  }

  @protected
  FutureOr<String> processErrorResponse(R errorResponse) =>
      errorResponse.toString();
}
