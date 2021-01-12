part of 'core.dart';

const _boxNameDatastoreMetadata = 'datastoreMetadata';

typedef DatastoreCreator<T extends Datastore> = T Function();

class _DatastoreWidget<T extends Datastore> extends StatefulWidget {
  final Widget child;
  final DatastoreCreator createDatastore;

  const _DatastoreWidget({
    Key key,
    @required this.child,
    @required this.createDatastore,
  }) : super(key: key);

  @override
  State<_DatastoreWidget> createState() => createDatastore();
}

class _InheritedDatastore extends InheritedWidget {
  final Datastore data;
  final Widget child;

  _InheritedDatastore({
    Key key,
    @required this.data,
    @required this.child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;
}

abstract class Datastore extends State<_DatastoreWidget>
    with WidgetsBindingObserver {
  var _completer = Completer<void>();

  Future<void> get initialized => _completer.future;
  bool get isInitialized => _completer.isCompleted;
  bool _initializationStarted = false;
  StreamSubscription<ConnectivityResult> _connectivitySub;

  final BehaviorSubject<bool> _loadingSubject = BehaviorSubject.seeded(false);
  ValueStream<bool> get loadingStream => _loadingSubject.stream;

  Future<WebSocket> socketFuture;
  Box _metadataBox;

  E getMetadata<E>(String key, {E defaultValue}) {
    return _metadataBox.get(key, defaultValue: defaultValue);
  }

  Future<void> putMetadata<E>(String key, E value) {
    return _metadataBox.put(key, value);
  }

  Map<String, String> createLastSyncParams({bool incremental = true});

  @override
  void initState() {
    super.initState();
    initializeAsync();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _establishTickerSocket();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub.cancel();
    _loadingSubject.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Lifecycle State: $state');
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      _establishTickerSocket();
    } else if (socketFuture != null) {
      // closeCode 1001: "going away"
      socketFuture
          .timeout(Duration.zero, onTimeout: () => null)
          .then((socket) => socket?.close(1001, "backgrounded"));
      socketFuture = null;
    }
  }

  Future<void> initializeAsync() async {
    if (_initializationStarted) return;
    _initializationStarted = true;

    debugPrint('[datastore] Initializing');
    if (!kIsWeb) await Hive.initFlutter();
    _metadataBox = await Hive.openBox(_boxNameDatastoreMetadata);

    registerTypeAdapters();
    await openBoxes();

    debugPrint('[datastore] Ready');
    _establishTickerSocket();
    _completer.complete();
    // fetchUpdates();

    if (mounted) {
      setState(() {});
    }
  }

  void registerTypeAdapters();

  Future<void> openBoxes({bool clear = false});

  Future<void> clear() async {
    await initialized;
    debugPrint('[datastore] Clearing');

    _completer = Completer<void>();
    await _metadataBox.deleteFromDisk();
    _metadataBox = await Hive.openBox(_boxNameDatastoreMetadata);
    await openBoxes(clear: true);

    debugPrint('[datastore] Clearing Done');
    _completer.complete();
  }

  void _establishTickerSocket() async {
    final login = Core.login(context);
    if (!login.isSignedIn || socketFuture != null) {
      return;
    }
    final baseUri = Uri.parse('${login._serverUrl}/v1/ticker');
    final uriBuilder = UriBuilder.fromUri(baseUri)
      ..scheme = baseUri.scheme == "https" ? "wss" : "ws";
    uriBuilder.queryParameters.addAll(createLastSyncParams(incremental: true));

    // ignore: close_sinks
    socketFuture = WebSocket.connect(
      uriBuilder.toString(),
      headers: login.authHeaders,
    );
    socketFuture.then((socket) {
      debugPrint('[datastore] Ticker channel created');
      return socket.listen((message) {
        debugPrint("[datastore] Ticker message");
        _parseResponseString(message);
      }, onError: (err) {
        debugPrint("[datastore] Ticker error: $err");
        socketFuture = null;
      }, onDone: () {
        debugPrint(
            '[datastore] Ticker closed: ${socket.closeCode}, ${socket.closeReason}');
        socketFuture = null;
      });
    }, onError: (err) {
      debugPrint("[datastore] Ticker socket error: $err");
      socketFuture = null;
    });
  }

  void fetchUpdates({bool incremental = true}) async {
    if (_loadingSubject.hasValue && _loadingSubject.value) return;
    final login = Core.login(context);
    if (!login.isSignedIn) {
      _setLoadingError("Not Signed In");
      return;
    }
    _setLoading(true);
    debugPrint('[datastore] Fetching Updates');

    final uriBuilder =
        UriBuilder.fromUri(Uri.parse('${login._serverUrl}/v1/sync'));
    uriBuilder.queryParameters
        .addAll(createLastSyncParams(incremental: incremental));

    try {
      final httpRequest = Request('get', uriBuilder.build());
      httpRequest.headers.addAll(login.authHeaders);
      final response = await login._client.send(httpRequest);

      if (response.statusCode == 200) {
        await _parseResponse(response);
        _setLoading(false);
      } else {
        String responseString = await response.stream.bytesToString();
        debugPrint('Loading Error: $responseString');
        _setLoadingError(responseString);
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        _setLoadingError('Server Unreachable');
      } else {
        _setLoadingError(e.toString());
      }
    }
  }

  void _setLoadingError(String errorMessage) {
    _loadingSubject.addError(errorMessage);
  }

  void _setLoading(bool loading) {
    _loadingSubject.add(loading);
  }

  Future<void> _parseResponse(StreamedResponse response) async =>
      _parseResponseString(await response.stream.bytesToString());

  Future<void> _parseResponseString(String responseString) async {
    if (responseString.isNotEmpty) {
      final responseMap = jsonDecode(responseString) as Map<String, dynamic>;
      await _parseResponseMap(responseMap);
      setState(() {
        // Notify any listening widgets
      });
      Core.login(context).setState(() {});
    }
  }

  Future<bool> _parseResponseMap(
    Map<String, dynamic> response, {
    bool clearData = false,
  }) async {
    debugPrint('[datastore] Parsing response map');
    await initialized;
    if (clearData ||
        response.containsKey('clearData') && response['clearData']) {
      await clear();
    }
    if (response.containsKey('session')) {
      debugPrint('[datastore] Parsing session');
      final success = await Core.login(context)
          ._parseSession(response['session'] as Map<String, dynamic>);
      if (!success) {
        return false;
      }
    }
    if (response.containsKey('data')) {
      debugPrint('[datastore] Parsing data');
      await parseData(response['data'] as Map<String, dynamic>);
    }
    if (response.containsKey('debug')) {
      debugPrint(response['debug'].toString());
    }
    debugPrint('[datastore] Response parsed');
    return true;
  }

  Future<void> parseData(Map<String, dynamic> data);

  @override
  Widget build(BuildContext context) => _InheritedDatastore(
        key: widget.key,
        child: widget.child,
        data: this,
      );
}
