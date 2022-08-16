import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:uri/uri.dart';

import 'api_error_response.dart';
import 'global.dart';
import 'dispatcher.dart';
import 'account.dart';
import 'account_hooks.dart';

const _persistKeyApiBaseUrl = 'apiBaseUrl';

typedef ResponseTransformer<R> = FutureOr<R?> Function(String);
typedef ResponseListener<R> = FutureOr<void> Function(
  R? response,
  dynamic tag,
);

typedef ErrorResponseTransformer = FutureOr<ApiErrorResponse> Function(
    Response response);

class ApiClient<R> with AccountHooks<R> {
  Dispatcher dispatcher = HttpClientDispatcher();
  final ResponseTransformer<R?> transformResponse;
  final ErrorResponseTransformer transformErrorResponse;
  final List<ResponseListener<R>> _responseListeners = [];

  Uri _apiBaseUrl = Uri();
  Uri get apiBaseUrl => _apiBaseUrl;
  set apiBaseUrl(Uri url) {
    _apiBaseUrl = url;
    account.persist(_persistKeyApiBaseUrl, url.toString());
  }

  ApiClient({
    required this.transformResponse,
    this.transformErrorResponse = _defaultErrorResponseTransformer,
  });

  @override
  Future<void> initialize(Account<R> account) async {
    await super.initialize(account);
    _apiBaseUrl =
        Uri.tryParse(account.getPersisted(_persistKeyApiBaseUrl) ?? '') ??
            Uri();
  }

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

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path) {
    final builder = UriBuilder.fromUri(apiBaseUrl);
    builder.path += path;
    return builder;
  }

  void Function() addResponseListener(ResponseListener<R> listener) {
    _responseListeners.add(listener);
    return () {
      _responseListeners.remove(listener);
    };
  }

  Future<ApiErrorResponse?> sendRequest(
    BaseRequest request, {
    FutureOr<bool> Function(R?)? callback,
    dynamic tag,
  }) async {
    if (closed) return ApiErrorResponse(message: 'Client Closed');
    final completer = Completer();
    account.registerOngoingOperation(completer.future);
    try {
      OTL.logger?.d('[api] Sending request to ${request.url}');
      request.headers.addAll(requestHeaders);
      final response = await dispatcher.dispatch(request);

      // Show request result
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await processResponseString(
          response.body,
          callback: callback,
          tag: tag,
        );
        return null;
      } else {
        return transformErrorResponse(response);
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
    FutureOr<bool> Function(R?)? callback,
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
    FutureOr<bool> Function(R?)? callback,
    dynamic tag,
  }) async {
    final completer = Completer<void>();
    account.registerOngoingOperation(completer.future);
    try {
      OTL.logger?.d('[api] Processing response');
      if (callback != null && !await callback.call(response)) {
        return;
      }
      for (final processResponse in _responseListeners) {
        await processResponse(response, tag);
      }
    } finally {
      completer.complete();
      OTL.logger?.d('[api] Response processed');
    }
  }

  @protected
  FutureOr<String> processErrorResponse(R errorResponse) =>
      errorResponse.toString();
}

ApiErrorResponse _defaultErrorResponseTransformer(Response response) =>
    ApiErrorResponse(
      statusCode: response.statusCode,
      message:
          response.bodyBytes.isEmpty ? 'Unknown Server Error' : response.body,
    );
