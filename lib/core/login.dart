part of 'core.dart';

const _gidShift = 10; // Must match up with the server
const _keyServerUrl = "serverUrl";
const _keyGid = "gid";
const _keySessionId = "sessionId";
const _keyUserId = "userId";
const _keyUserName = "userName";
const _keyPermissions = "permissions";
const _keyUsedIds = "usedIds";

const VIEW_BASIC = 1 << 0;
const VIEW_CONTRIBUTIONS = 1 << 1;
const VIEW_SENSITIVE = 1 << 2;
const VIEW_FILES = 1 << 3;
const VIEW_CONTACTS = 1 << 4;

// Basic permissions
const permissionViewBasic = 1 << 0; // Model - BasicVolunteer, BasicStay
const permissionAddCheckin = 1 << 1; // Action - Add Checkin
const permissionAddContribution = 1 << 2; // Action - Add Contribution
const permissionBasicPH1 = 1 << 3;
const permissionBasicPH2 = 1 << 4;
const permissionBasicPH3 = 1 << 5;
const permissionBasicPH4 = 1 << 6;

// Admin
const permissionViewVolunteerDetailed = 1 << 7; // Model - DetailedVolunteer
const permissionEditVolunteerDetailed = 1 << 8;

// Files
const permissionViewFiles = 1 << 9; // Model - File
const permissionEditFiles = 1 << 10;

// Contacts
const permissionViewContacts = 1 << 11;
const permissionEditContacts = 1 << 12;

// Checkout Manager
const permissionViewAccounting = 1 << 13; // Model - (Full)Stay, Payment
const permissionEditAccounting =
    1 << 14; // Action - edit accounting - dates, amounts, rates, etc.

// SuperAdmin
const permissionSuperAdmin = 1 << 25; // Misc super-admin perissions
const permissionViewEditVolunteerSensitive =
    permissionSuperAdmin; // Model - (Full)Volunteer - Team, Notes

// Client-side
const permissionClientQuickCheckin =
    permissionSuperAdmin; // Action - Checkin without photo or declaration
const permissionClientSortFilter =
    permissionSuperAdmin; // Action - Sort data on the client

const permissionReceivePayments =
    1 << 28; // Action - Mark Contribution as Received
const permissionGrantPermissions = 1 << 29; // Action - Grant Permissions
const permissionCheckedOut = 1 << 30; // Access the system while not checked in

// Dev
const permissionDev = 1 << 31;
const permissionViewModelsByID = permissionDev;
const permissionMasquerade = permissionDev;
const permissionSwitchDatabase = permissionDev;

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
    debugPrint('Logging In with Google');
    final request =
        Request('post', Uri.parse('$serverUrl/v1/login/google-id-token'));
    request.headers['Authorization'] = 'Bearer $idToken';
    return sendLoginRequest(context, request);
  }

  Future<String> loginWithSessionId(
      BuildContext context, String sessionId) async {
    debugPrint('Logging In with Session ID');
    final request = Request('get', Uri.parse('$serverUrl/v1/sync'));
    request.headers['Authorization'] = 'SessionId $sessionId';
    return sendLoginRequest(context, request);
  }

  Future<String> sendLoginRequest(BuildContext context, Request request) async {
    debugPrint('Clearing Data.');
    await Core.datastore(context).clear();
    debugPrint('Data Cleared, sending request');
    try {
      final response = await _client.send(request);
      if (response.statusCode == 200) {
        _usedIds = 0;
        await storage.write(key: _keyUsedIds, value: '0');
        await Core.datastore(context)._parseResponse(response);
        debugPrint("Login Successful");

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
      debugPrint("Session not parsed");
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
    await Core.api(context).clearQueue();
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
    debugPrint('  sessionId: $_sessionId');
    debugPrint('        gid: $_gid');
    debugPrint('   gid base: ${_gid << _gidShift}');
    debugPrint('   used ids: $_usedIds');
    debugPrint('   next gid: ${_usedIds | (_gid << _gidShift)}');
    debugPrint('permissions: $_permissions');
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
