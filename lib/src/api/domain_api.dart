part of 'api.dart';

typedef ResponseProcessor = FutureOr<void> Function(
    Map<String, dynamic> response);

const _boxPrefixPersist = 'domain';

abstract class DomainApi<T extends ApiCubit> {
  final T api;
  final String domain;
  final List<ResponseProcessor> _responseProcessors = [];
  late final Box _persist;
  ActionQueueCubit get actionQueue;
  Map<String, String> get headers => api.headers;

  DomainApi(this.domain, this.api) {
    Hive.openBox(_boxPrefixPersist + domain).then((box) async {
      _persist = box;
      debugPrint('[api] Ready');
    });
  }

  String createUrl(String path) {
    return createUriBuilder(path).toString();
  }

  UriBuilder createUriBuilder(String path);

  E? getMetadata<E>(String key, {E? defaultValue}) {
    return _persist.get(key, defaultValue: defaultValue);
  }

  Future<void> putMetadata<E>(String key, E value) {
    return _persist.put(key, value);
  }

  void addResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.add(processor);
  }

  void removeResponseProcessor(ResponseProcessor processor) {
    _responseProcessors.remove(processor);
  }

  Future<String?> sendRequest(BaseRequest request) async {
    try {
      final response = await api.sendRequest(request);
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
    }
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
