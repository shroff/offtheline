part of 'core.dart';

const _gidShift = 10; // Must match up with the server
const _keyServerUrl = "serverUrl";
const _keyGid = "gid";
const _keySessionId = "sessionId";
const _keyUserId = "userId";
const _keyUserName = "userName";
const _keyPermissions = "permissions";
const _keyUsedIds = "usedIds";

class Login extends StatefulWidget {
  final Widget child;

  const Login({Key key, @required this.child}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _InheritedLogin extends InheritedWidget {
  final _LoginState data;
  final Widget child;

  _InheritedLogin({
    Key key,
    @required this.data,
    @required this.child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;
}

class _LoginState extends State<Login> {
  final _completer = Completer<void>();
  Future<void> get initialized => _completer.future;
  bool get isInitialized => _completer.isCompleted;
  bool _initializationStarted = false;

  final Storage storage = createStorage();

  final BaseClient _client = createHttpClient();
  String _serverUrl = "";
  int _gid;
  String _sessionId;
  int _userId;
  String _userName;
  int _permissions;
  int _usedIds;

  String get serverUrl => _serverUrl;
  bool get isSignedIn => _sessionId != null;
  Map<String, String> authHeaders = {};

  int get permissions => _permissions;
  int get userId => _userId;
  String get userName => _userName;

  @override
  void initState() {
    super.initState();
    initializeAsync();
  }

  Future<void> initializeAsync() async {
    if (_initializationStarted) return;
    _initializationStarted = true;
    await storage.initialize();
    _serverUrl = await storage.read(key: _keyServerUrl);
    final sessionId = await storage.read(key: _keySessionId);
    final gidString = await storage.read(key: _keyGid);
    final usedIdsString = await storage.read(key: _keyUsedIds);
    final userIdString = await storage.read(key: _keyUserId);
    final userName = await storage.read(key: _keyUserName);
    final permissionsString = await storage.read(key: _keyPermissions);
    if (serverUrl != null &&
        sessionId != null &&
        gidString != null &&
        usedIdsString != null &&
        permissionsString != null &&
        userIdString != null) {
      final gid = int.tryParse(gidString);
      final usedIds = int.tryParse(usedIdsString);
      final userId = int.tryParse(userIdString);
      final permissions = int.tryParse(permissionsString);
      if (gid != null &&
          usedIds != null &&
          permissions != null &&
          userId != null) {
        setState(() {
          _sessionId = sessionId;
          _gid = gid;
          _usedIds = usedIds;
          _userId = userId;
          _userName = userName;
          _permissions = permissions;
          authHeaders['Authorization'] = 'SessionId $_sessionId';
        });
      }
    }
    _completer.complete();
  }

  void setServerUrl(Uri serverUri) async {
    _serverUrl = serverUri.toString();
    await storage.write(key: _keyServerUrl, value: _serverUrl);
    setState(() {});
  }

  Future<String> loginWithGoogle(
      BuildContext context, String email, String idToken) async {
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
    await Core.datastore(context).clear();
    await Core.api(context).clear();

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

  bool hasPermission(int permission) {
    return (permission & _permissions) != 0;
  }

  Future<void> _parseSession(Map<String, dynamic> session) async {
    final int gid = session['gid'];
    final String sessionId = session['sessionId'];
    final loginUser = _parseUser(session['user']);

    if (loginUser == null || gid == null || sessionId == null) {
      // TODO: #silentfail
      debugPrint("[login] Session not parsed");
      return;
    }

    bool changed = false;
    if (this._sessionId != sessionId) {
      authHeaders['Authorization'] = 'SessionId $sessionId';
      await storage.write(key: _keySessionId, value: sessionId);
      changed = true;
    }
    if (this._gid != gid) {
      await storage.write(key: _keyGid, value: gid.toString());
      changed = true;
    }

    if (this._permissions != loginUser.permissions) {
      await storage.write(
          key: _keyPermissions, value: loginUser.permissions.toString());
      changed = true;
    }
    if (this._userId != loginUser.id) {
      await storage.write(key: _keyUserId, value: loginUser.id.toString());
      changed = true;
    }
    if (this._userName != loginUser.name) {
      await storage.write(key: _keyUserName, value: loginUser.name);
      changed = true;
    }

    if (changed) {
      setState(() {
        _gid = gid;
        _sessionId = sessionId;
        _permissions = loginUser.permissions;
        _userId = loginUser.id;
        _userName = loginUser.name;
      });
    }
  }

  _LoginUser _parseUser(Map<String, dynamic> user) {
    final loginUser = _LoginUser();

    loginUser.id = user['id'];
    loginUser.name = '${user['first_name']} ${user['last_name']}';
    loginUser.permissions = user['permissions'];

    if (loginUser.id == null ||
        loginUser.permissions == null ||
        loginUser.name == null) return null;

    return loginUser;
  }

  Future<int> getNextGid() async {
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
      _gid = null;
      _usedIds = null;
      _permissions = null;
      _userId = null;
      _userName = null;
    });
  }

  void printSessionDetails() {
    debugPrint('[login]   sessionId: $_sessionId');
    debugPrint('[login]         gid: $_gid');
    debugPrint('[login]    gid base: ${_gid << _gidShift}');
    debugPrint('[login]    used ids: $_usedIds');
    debugPrint('[login]    next gid: ${_usedIds | (_gid << _gidShift)}');
    debugPrint('[login] permissions: $_permissions');
  }

  @override
  Widget build(BuildContext context) => _InheritedLogin(
        key: widget.key,
        data: this,
        child: widget.child,
      );
}

class _LoginUser {
  String name;
  int id;
  int permissions;
}
