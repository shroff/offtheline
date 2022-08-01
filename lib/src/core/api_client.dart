import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:uri/uri.dart';

import 'api_error_response.dart';
import 'logger.dart';
import 'domain.dart';
import 'domain_hooks.dart';

const _persistKeyApiBaseUrl = "apiBaseUrl";

typedef ResponseTransformer<R> = FutureOr<R?> Function(String);
typedef ResponseProcessor<R> = FutureOr<void> Function(
  R? response,
  dynamic tag,
);

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

  @override
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

  Future<ApiErrorResponse?> sendRequest(
    BaseRequest request, {
    FutureOr<void> Function(R?)? callback,
    dynamic tag,
  }) async {
    if (closed) return ApiErrorResponse(message: "Client Closed");
    final completer = Completer();
    domain.registerOngoingOperation(completer.future);
    try {
      logger?.d('[api] Sending request to ${request.url}');
      request.headers.addAll(requestHeaders);
      final response = await _client.send(request);

      final responseString = await response.stream.bytesToString();
      // Show request result
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await processResponseString(responseString,
            callback: callback, tag: tag);
        return null;
      } else {
        return ApiErrorResponse(
            statusCode: response.statusCode,
            message: responseString.isEmpty
                ? 'Unknown Server Error'
                : responseString);
      }
    } on SocketException {
      return ApiErrorResponse(message: 'Server Unreachable');
    } catch (e) {
      return ApiErrorResponse(message: e.toString());
    } finally {
      completer.complete();
    }
  }

  Future<void> processResponseString(
    String responseString, {
    FutureOr<void> Function(R?)? callback,
    dynamic tag,
  }) async {
    processResponse(
      await transformResponse(responseString),
      callback: callback,
      tag: tag,
    );
  }

  @nonVirtual
  Future<void> processResponse(
    R? response, {
    FutureOr<void> Function(R?)? callback,
    dynamic tag,
  }) async {
    final completer = Completer<void>();
    domain.registerOngoingOperation(completer.future);
    try {
      logger?.d('[api] Processing response');
      if (callback != null) await callback.call(response);
      for (final processResponse in _responseProcessors) {
        await processResponse(response, tag);
      }
    } finally {
      completer.complete();
      logger?.d('[api] Response processed');
    }
  }

  @protected
  FutureOr<String> processErrorResponse(R errorResponse) =>
      errorResponse.toString();
}
