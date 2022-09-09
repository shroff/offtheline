import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:uri/uri.dart';

import 'api_error_response.dart';
import 'global.dart';
import 'dispatcher.dart';
import 'account.dart';
import 'account_listener.dart';

const _persistKeyApiBaseUrl = 'apiBaseUrl';

typedef ResponseTransformer<R extends ApiResponse> = FutureOr<R> Function(
  Response response,
  dynamic tag,
);
typedef ResponseListener = FutureOr<void> Function(
  Response response,
  dynamic tag,
);

class ApiClient<Datastore> with AccountListener<Datastore> {
  Dispatcher dispatcher = HttpClientDispatcher();
  final List<ResponseListener> _responseListeners = [];

  Uri _apiBaseUrl = Uri();
  Uri get apiBaseUrl => _apiBaseUrl;
  set apiBaseUrl(Uri url) {
    _apiBaseUrl = url;
    account.persistence.persist(_persistKeyApiBaseUrl, url.toString());
  }

  ApiClient();

  @override
  Future<void> initialize(Account<Datastore> account) async {
    await super.initialize(account);
    _apiBaseUrl = Uri.tryParse(
            account.persistence.getPersisted(_persistKeyApiBaseUrl) ?? '') ??
        Uri();
  }

  Map<String, String> _requestHeaders = const {};
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

  UriBuilder createUriBuilder([String? path]) {
    final builder = UriBuilder.fromUri(apiBaseUrl);
    if (path != null) {
      builder.path += path;
    }
    return builder;
  }

  void Function() addResponseListener(ResponseListener listener) {
    _responseListeners.add(listener);
    return () {
      _responseListeners.remove(listener);
    };
  }

  Future<ApiErrorResponse?> sendRequest(
    BaseRequest request, {
    dynamic tag,
  }) async {
    if (closed) return ApiErrorResponse(message: 'Client Closed');
    final completer = Completer();
    account.registerOngoingOperation(completer.future);
    try {
      OTL.logger?.d('[api] Sending request to ${request.url}');
      request.headers.addAll(requestHeaders);
      final response = await dispatcher.dispatch(request);

      processResponse(response, tag: tag);
      if (response.errorSummary != null) {
        return ApiErrorResponse(message: response.errorSummary!);
      }
      return null;
    } on SocketException {
      return ApiErrorResponse(message: 'Server Unreachable');
    } catch (e) {
      return ApiErrorResponse(message: e.toString());
    } finally {
      completer.complete();
    }
  }

  @nonVirtual
  Future<void> processResponse(
    Response response, {
    dynamic tag,
  }) async {
    final completer = Completer<void>();
    account.registerOngoingOperation(completer.future);
    try {
      OTL.logger?.d('[api] Processing response');
      for (final listener in _responseListeners) {
        await listener(response, tag);
      }
    } finally {
      completer.complete();
      OTL.logger?.d('[api] Response processed');
    }
  }
}

ApiErrorResponse _defaultErrorResponseTransformer(Response response) =>
    ApiErrorResponse(
      statusCode: response.statusCode,
      message:
          response.bodyBytes.isEmpty ? 'Unknown Server Error' : response.body,
    );

abstract class ApiResponse<R> {
  String? get errorSummary;
  String? get errorDetails;
  R? get data;
}
