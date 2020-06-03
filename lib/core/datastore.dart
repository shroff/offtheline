part of 'core.dart';

const _boxNameMetadata = 'metadata';

class DatastoreWidget<T extends Datastore> extends StatefulWidget {
  final Widget child;
  final T Function() createDatastore;

  const DatastoreWidget({
    Key key,
    @required this.child,
    @required this.createDatastore,
  }) : super(key: key);

  @override
  State<DatastoreWidget> createState() => createDatastore();
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

abstract class Datastore extends State<DatastoreWidget> {
  var _completer = Completer<void>();
  Future<void> get initialized => _completer.future;
  bool get isInitialized => _completer.isCompleted;
  bool _initializationStarted = false;

  BehaviorSubject<bool> _loadingSubject;

  ValueStream<bool> get loadingStream => _loadingSubject.stream;

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
  }

  Future<void> initializeAsync() async {
    if (_initializationStarted) return;
    _initializationStarted = true;

    debugPrint('Datastore Initializing');
    _loadingSubject = BehaviorSubject.seeded(false);
    if (!kIsWeb) await Hive.initFlutter();
    registerTypeAdapters();

    _metadataBox = await Hive.openBox(_boxNameMetadata);
    await openBoxes();

    debugPrint('Datastore Ready');
    _completer.complete();
    fetchUpdates();
  }

  void registerTypeAdapters();

  Future<void> openBoxes({bool clear = false});

  Future<void> clear() async {
    await initialized;
    debugPrint('Clearing datastore');

    _completer = Completer<void>();
    await _metadataBox.deleteFromDisk();
    _metadataBox = await Hive.openBox(_boxNameMetadata);
    await openBoxes(clear: true);
  }

  @override
  void dispose() {
    _loadingSubject.close();
    super.dispose();
  }

  void fetchUpdates({bool incremental = true}) async {
    if (_loadingSubject.hasValue && _loadingSubject.value) return;
    final login = Core.login(context);
    if (!login.isSignedIn) {
      _setLoadingError("Not Signed In");
      return;
    }
    _setLoading(true);
    debugPrint('Fetching Updates');

    final uriBuilder = UriBuilder.fromUri(Uri.parse('${login._serverUrl}/v1/sync'));
    uriBuilder.queryParameters.addAll(createLastSyncParams(incremental: incremental));
    debugPrint(uriBuilder.toString());

    try {
      final httpRequest = Request('get', uriBuilder.build());
      httpRequest.headers.addAll(login.authHeaders);
      final response = await login._client.send(httpRequest);

      if (response.statusCode == 200) {
        await _parseResponse(response);
        _setLoading(false);
      } else {
        String responseString = await response.stream.bytesToString();
        debugPrint(responseString);
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

  Future<void> _parseResponse(StreamedResponse response) async {
    final responseString = await response.stream.bytesToString();
    if (responseString.isNotEmpty) {
      final responseMap = jsonDecode(responseString) as Map<String, dynamic>;
      _parseResponseMap(responseMap);
      setState(() {
        // Notify any listening widgets
      });
    }
  }

  void _parseResponseMap(Map<String, dynamic> response, {bool clearData = false}) async {
    debugPrint('Parsing response map');
    response.keys.forEach((element) {
      debugPrint(element);
    });
    await initialized;
    if (clearData || response.containsKey('clearData') && response['clearData']) {
      await clear();
    }
    if (response.containsKey('session')) {
      await Core.login(context)._parseSession(response['session'] as Map<String, dynamic>);
    }
    if (response.containsKey('data')) {
      await parseData(response['data'] as Map<String, dynamic>);
    }
    if (response.containsKey('debug')) {
      debugPrint(response['debug'].toString());
    }
    debugPrint('Response parsed');
  }

  Future<void> parseData(Map<String, dynamic> data);

  @override
  Widget build(BuildContext context) => _InheritedDatastore(
        key: widget.key,
        child: widget.child,
        data: this,
      );
}
