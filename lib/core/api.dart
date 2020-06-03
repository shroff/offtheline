part of 'core.dart';

const _boxNameRequestQueue = 'requestQueue';

class Api extends StatefulWidget {
  final Widget child;

  const Api({Key key, @required this.child}) : super(key: key);

  @override
  State<Api> createState() => _ApiState();
}

class _InheritedApi extends InheritedWidget {
  final _ApiState data;
  final Widget child;

  _InheritedApi({Key key, this.data, this.child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;
}

class _ApiState extends State<Api> {
  final _completer = Completer<void>();
  Future<void> get initialized => _completer.future;
  bool get isInitialized => _completer.isCompleted;
  bool _initializationStarted = false;

  Box<ApiRequest> requestQueue;

  ApiRequest _currentlySyncingRequest;

  ApiStatus _status = ApiStatus.INITIALIZING;

  ApiStatus get status => _status;

  String _statusDetails;

  String get statusDetails => _statusDetails;

  bool get isSyncing => _currentlySyncingRequest != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeAsync();
  }

  Future<void> initializeAsync() async {
    if (_initializationStarted) return;
    _initializationStarted = true;

    debugPrint('API Waiting for initialization');
    await Core.login(context).initialized;
    await Core.datastore(context).initialized;

    debugPrint('API Initializing');
    Hive.registerAdapter(UploadApiRequestAdapter());
    Hive.registerAdapter(SimpleApiRequestAdapter());
    requestQueue = await Hive.openBox(_boxNameRequestQueue);

    debugPrint('API Ready');
    _completer.complete();
    sendNextRequest();
  }

  Future<void> enqueue(ApiRequest request) async {
    debugPrint('Request enqueued');
    await initialized;
    await requestQueue.add(request);
    sendNextRequest();
  }

  Future<void> deleteFirstRequest() async {
    await initialized;
    if (requestQueue.isEmpty) return;
    await requestQueue.deleteAt(0);
    sendNextRequest();
  }

  Future<void> clearQueue() async {
    await initialized;
    await requestQueue.clear();
  }

  void sendNextRequest() async {
    debugPrint('Sync triggered');
    await initialized;
    if (requestQueue.isEmpty) {
      _updateStatus(ApiStatus.DONE);
      debugPrint('Nothing to sync');
      return;
    }
    if (_status == ApiStatus.SYNCING) {
      debugPrint('Syncing ongoing');
      return;
    }
    final login = Core.login(context);
    if (!login.isSignedIn) {
      debugPrint('API Not Signed In. Clearing');
      await clearQueue();
      _updateStatus(ApiStatus.DONE);
      return;
    }
    final request = requestQueue.getAt(0);
    _updateStatus(ApiStatus.SYNCING, details: request.description);

    final queryParams = Core.datastore(context).createLastSyncParams();
    final uriBuilder =
        UriBuilder.fromUri(Uri.parse('${login._serverUrl}${request.endpoint}'));
    uriBuilder.queryParameters.addAll(queryParams);

    try {
      final httpRequest = await request.createRequest(uriBuilder.build());
      httpRequest.headers.addAll(login.authHeaders);
      final response = await login._client.send(httpRequest);

      // Show request result
      if (response.statusCode == 200) {
        _updateStatus(ApiStatus.DONE);
        deleteFirstRequest();
        Core.datastore(context)._parseResponse(response);
      } else {
        final details = await response.stream.bytesToString();
        _updateStatus(ApiStatus.ERROR, details: details);
      }
    } catch (e) {
      if (e is SocketException) {
        _updateStatus(ApiStatus.SERVER_UNREACHABLE);
      } else {
        _updateStatus(ApiStatus.ERROR, details: e.toString());
        rethrow;
      }
    }
  }

  void _updateStatus(ApiStatus status, {String details}) {
    debugPrint('$status: $details');
    setState(() {
      _status = status;
      _statusDetails = details;
    });
  }

  @override
  Widget build(BuildContext context) => _InheritedApi(
        key: widget.key,
        data: this,
        child: widget.child,
      );
}

enum ApiStatus {
  INITIALIZING,
  DONE,
  SYNCING,
  ERROR,
  WAITING_AUTH,
  SERVER_UNREACHABLE,
}
