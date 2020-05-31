part of 'appcore.dart';

const _boxNameRequestQueue = 'requestQueue';

class Api extends StatefulWidget {
  final Logger logger;
  final Widget child;

  const Api({Key key, this.logger, @required this.child}) : super(key: key);

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
    widget.logger.log('API Waiting for Datastore');
    await Core.datastore(context).initialized;
    widget.logger.log('API Initializing');
    Hive.registerAdapter(UploadApiRequestAdapter());
    Hive.registerAdapter(SimpleApiRequestAdapter());
    requestQueue = await Hive.openBox(_boxNameRequestQueue);
    widget.logger.log('API Ready');
    _completer.complete();
    _updateStatus(ApiStatus.DONE);
    sync();
  }

  void enqueue(ApiRequest request) async {
    widget.logger.log('Request enqueued');
    await initialized;
    requestQueue.add(request);
    sync();
  }

  void deleteFirstRequest() async {
    await initialized;
    if (requestQueue.isEmpty) return;
    requestQueue.deleteAt(0);
    sync();
  }

  void sync() async {
    widget.logger.log('Sync triggered');
    await initialized;
    if (requestQueue.isEmpty) {
      _updateStatus(ApiStatus.DONE);
      widget.logger.log('Nothing to sync');
      return;
    }
    if (_status == ApiStatus.SYNCING) {
      widget.logger.log('Syncing ongoing');
      return;
    }
    final request = requestQueue.getAt(0);
    _updateStatus(ApiStatus.SYNCING, details: request.description);
    final login = Core.login(context);
    if (!login.isSignedIn) {
      _updateStatus(ApiStatus.WAITING_AUTH);
      return;
    }
    await Core.datastore(context).initialized;

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
    widget.logger.log('$status: $details');
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
