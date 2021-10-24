import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

import 'domain.dart';
import 'domain_hooks.dart';

const _persistKeyApiBaseUrl = "apiBaseUrl";

typedef ResponseTransformer<R> = FutureOr<R?> Function(String);
typedef ResponseProcessor<R> = FutureOr<void> Function(R response);

class ApiClient<R> with DomainHooks<R> {
  final Client _client = Client();
  final ResponseTransformer<R?> transformResponse;
  final List<ResponseProcessor<R>> _responseProcessors = [];

  Uri _apiBaseUrl = Uri();
  Uri get apiBaseUrl => _apiBaseUrl;
  set apiBaseUrl(Uri url) {
    _apiBaseUrl = url;
    domain.persist(_persistKeyApiBaseUrl, url.toString());
  }

  ApiClient({
    required this.transformResponse,
  });

  Future<void> initialize(Domain<R> domain) async {
    await super.initialize(domain);
    _apiBaseUrl =
        Uri.tryParse(domain.getPersisted(_persistKeyApiBaseUrl) ?? "") ?? Uri();
  }

  bool get valid => true;

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
    if (closed) return "Client Closed";
    final completer = Completer();
    domain.registerOngoingOperation(completer.future);
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
      if (response != null) {
        processResponse(response);
      }
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
