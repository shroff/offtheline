part of 'appcore.dart';

const _boxNameMetadata = 'metadata';

class DatastoreWidget<T extends Datastore> extends StatefulWidget {
  final Logger logger;
  final Widget child;
  final T Function() createDatastore;

  const DatastoreWidget({
    Key key,
    this.logger,
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
  final _completer = Completer<void>();

  BehaviorSubject<bool> _loadingSubject;

  ValueStream<bool> get loadingStream => _loadingSubject.stream;

  Box _metadataBox;

  Future<void> get initialized => _completer.future;

  E getMetadata<E>(String key, {E defaultValue}) {
    return _metadataBox.get(key, defaultValue: defaultValue);
  }

  putMetadata<E>(String key, E value) {
    return _metadataBox.put(key, value);
  }

  Map<String, String> createLastSyncParams({bool incremental = true});

  @override
  void initState() {
    super.initState();
    widget.logger.log('Datastore Initializing');
    _loadingSubject = BehaviorSubject.seeded(false);
    initializeAsync();
  }

  Future<void> initializeAsync() async {
    if (!kIsWeb) await Hive.initFlutter();
    _metadataBox = await Hive.openBox(_boxNameMetadata);
    await initializeHive();

    widget.logger.log('Datastore Ready');
    _completer.complete();
    fetchUpdates();
  }

  Future<void> initializeHive();

  Future<void> deleteEverything() async {
    widget.logger.log('Clearing Data');
    await Hive.deleteFromDisk();
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
    widget.logger.log('Fetching Updates');

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
        widget.logger.log(responseString);
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
      await deleteEverything();
    }
    if (response.containsKey('session')) {
      await Core.login(context)._parseSession(response['session'] as Map<String, dynamic>);
    }
    if (response.containsKey('data')) {
      parseData(response['data'] as Map<String, dynamic>);
    }
    if (response.containsKey('debug')) {
      widget.logger.log(response['debug'].toString());
    }
    debugPrint('Response parsed');
  }

  void parseData(Map<String, dynamic> data);

  @override
  Widget build(BuildContext context) => _InheritedDatastore(
        key: widget.key,
        child: widget.child,
        data: this,
      );
}
