part of 'core.dart';

const _gidShift = 10; // Must match up with the server
const _keyServerUrl = "serverUrl";
const _keyGid = "gid";
const _keyUsedIds = "usedIds";
const _keySessionId = "sessionId";
const _keyUser = "user";

typedef UserParser<T extends LoginUser> = T Function(Map<String, dynamic>);

class _LoginWidget<T extends LoginUser> extends StatefulWidget {
  final Widget child;
  final UserParser<T> parseUser;

  const _LoginWidget({Key key, @required this.child, @required this.parseUser})
      : super(key: key);

  @override
  State<_LoginWidget> createState() => Login<T>();
}

class _InheritedLoginWidget extends InheritedWidget {
  final Login data;
  final Widget child;

  _InheritedLoginWidget({
    Key key,
    @required this.data,
    @required this.child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;
}

class Login<T extends LoginUser> extends State<_LoginWidget> {
  final _completer = Completer<void>();
  Future<void> get initialized => _completer.future;
  bool get isInitialized => _completer.isCompleted;
  bool _initializationStarted = false;

  final Storage storage = createStorage();

  final BaseClient _client = createHttpClient();
  String _serverUrl = "";
  String _sessionId;
  int _gid;
  int _usedIds;
  T _user;

  String get serverUrl => _serverUrl;
  bool get isSignedIn => _sessionId != null;
  Map<String, String> authHeaders = {};
  T get user => _user;

  @override
  void initState() {
    super.initState();
    initializeAsync();
  }

  Future<void> initializeAsync() async {
    if (_initializationStarted) return;
    _initializationStarted = true;
    await storage.initialize();
    _serverUrl = await storage.read(key: _keyServerUrl) ?? '';
    final sessionId = await storage.read(key: _keySessionId);
    final gidString = await storage.read(key: _keyGid) ?? '0';
    final usedIdsString = await storage.read(key: _keyUsedIds) ?? '0';
    final userJson = await storage.read(key: _keyUser) ?? '{}';
    final user = widget.parseUser(jsonDecode(userJson));

    if (gidString != null && usedIdsString != null) {
      final gid = int.tryParse(gidString);
      final usedIds = int.tryParse(usedIdsString);
      if (gid != null && usedIds != null) {
        _gid = gid;
        _usedIds = usedIds;
      }
    }
    if (sessionId != null && _gid != 0 && user != null) {
      _sessionId = sessionId;
      _user = user;
      authHeaders['Authorization'] = 'SessionId $_sessionId';
    }
    setState(() {});
    if (kDebugMode) {
      printSessionDetails();
    }
    _completer.complete();
  }

  void setServerUrl(Uri serverUri) async {
    _serverUrl = serverUri.toString();
    await storage.write(key: _keyServerUrl, value: _serverUrl);
    debugPrint('[login] Server set to ${_serverUrl}');
    setState(() {});
  }

  bool hasPermission(int permission) {
    return _user.hasPermission(permission);
  }

  String createUrl(String path) {
    return '$serverUrl$path';
  }

  Future<String> loginWithGoogle(
      BuildContext context, String email, String idToken) async {
    if (idToken?.isEmpty ?? true) {
      return "No ID Token given for Google login";
    }
    debugPrint('[login] Google');
    final request =
        Request('post', Uri.parse('$serverUrl/v1/login/google-id-token'));
    request.headers['Authorization'] = 'Bearer $idToken';
    return sendLoginRequest(context, request);
  }

  Future<String> loginWithSessionId(
      BuildContext context, String sessionId) async {
    debugPrint('[login] SessionID');
    final request = Request('get', Uri.parse('$serverUrl/v1/sync'));
    request.headers['Authorization'] = 'SessionId $sessionId';
    return sendLoginRequest(context, request);
  }

  Future<String> sendLoginRequest(BuildContext context, Request request) async {
    debugPrint('[login] Clearing Data');
    if (!kIsWeb) {
      await Core.datastore(context).clear();
      await Core.api(context).clear();
    }

    debugPrint('[login] Sending request');
    try {
      final response = await _client.send(request);
      if (response.statusCode == 200) {
        _usedIds = 0;
        await storage.write(key: _keyUsedIds, value: '0');
        await Core.datastore(context)._parseResponse(response);
        debugPrint("[login] Success");

        return null;
      } else {
        return response.stream.bytesToString();
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        return "Server Unreachable";
      } else {
        return e.toString();
      }
    }
  }

  Future<bool> _parseSession(Map<String, dynamic> session) async {
    final int gid = session['gid'];
    final String sessionId = session['sessionId'];
    final userJson = session['user'];
    final user = widget.parseUser(session['user']);

    if (user == null || gid == null || sessionId == null) {
      // TODO: #silentfail
      debugPrint("[login] Session not parsed");
      return false;
    }

    if (this._sessionId != sessionId) {
      authHeaders['Authorization'] = 'SessionId $sessionId';
      await storage.write(key: _keySessionId, value: sessionId);
    }
    if (this._gid != gid) {
      await storage.write(key: _keyGid, value: gid.toString());
    }

    if (this._user != user) {
      await storage.write(key: _keyUser, value: jsonEncode(userJson));
    }

    _gid = gid;
    _sessionId = sessionId;
    _user = user;
    return true;
  }

  Future<int> getNextAvailableId() async {
    int nextId = _usedIds++;
    await storage.write(key: _keyUsedIds, value: _usedIds.toString());
    return nextId | (_gid << _gidShift);
  }

  Future<void> signOut(BuildContext context) async {
    await storage.deleteAll();
    await storage.write(key: _keyServerUrl, value: serverUrl);
    await Core.datastore(context).clear();
    await Core.api(context).clear();
    authHeaders.remove('Authorization');
    setState(() {
      _sessionId = null;
      _gid = 0;
      _usedIds = 0;
      _user = null;
    });
  }

  void printSessionDetails() {
    debugPrint('[login]   sessionId: $_sessionId');
    debugPrint('[login]         gid: $_gid');
    debugPrint('[login]    gid base: ${_gid << _gidShift}');
    debugPrint('[login]    used ids: $_usedIds');
    debugPrint('[login]    next gid: ${_usedIds | (_gid << _gidShift)}');
    debugPrint('[login]        user: $_user');
  }

  @override
  Widget build(BuildContext context) => _InheritedLoginWidget(
        key: widget.key,
        data: this,
        child: widget.child,
      );
}

mixin LoginUser {
  int get id;
  int get permissions;
  String get name;

  bool hasPermission(int permission) {
    return (permission & permissions) != 0;
  }
}
