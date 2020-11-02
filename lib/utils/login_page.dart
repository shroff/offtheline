import 'package:appcore/core/core.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginWrapperPage extends StatelessWidget {
  final Widget child;
  final String googleClientId;

  const LoginWrapperPage(
      {Key key, @required this.child, @required this.googleClientId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Core.login(context).isSignedIn
        ? child
        : LoginPage(googleClientId: googleClientId);
  }
}

class LoginPage extends StatelessWidget {
  final googleClientId;
  const LoginPage({Key key, @required this.googleClientId}) : super(key: key);

  void _logInWithSessionId(BuildContext context) async {
    final login = Core.login(context);
    if (login.serverUrl.isEmpty) {
      return;
    }

    final sessionId = await showInputDialog(context,
        title: 'Session ID', labelText: 'Session ID');
    if (sessionId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(),
            ),
            Expanded(
              child: Text(
                'Logging In',
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
    String response = await login.loginWithSessionId(context, sessionId);
    _handleLoginResponse(response, context);
  }

  void _logInWithGoogle(BuildContext context) async {
    final login = Core.login(context);
    if (login.serverUrl.isEmpty) {
      return;
    }

    final googleSignIn = GoogleSignIn(
      scopes: [
        'email',
      ],
      clientId: googleClientId,
    );
    final user = await googleSignIn.signIn().catchError((error) => null,
        test: (error) =>
            error is PlatformException && error.message == 'sign_in_failed');
    final idToken = await user.authentication.then((auth) => auth.idToken);
    googleSignIn.disconnect();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(),
            ),
            Expanded(
              child: Text(
                'Logging In',
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
    String response = await login.loginWithGoogle(context, user.email, idToken);
    _handleLoginResponse(response, context);
  }

  void _handleLoginResponse(String response, BuildContext context) async {
    Navigator.of(context).pop();

    if (response == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
    if (response != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Login Error'),
          content: Text(
            response,
            softWrap: true,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final login = Core.login(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: FixedPageBody(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (login.canChangeServerUrl)
                RaisedButton(
                  child: login.serverUrl?.isEmpty ?? true
                      ? Text('Set Server Address')
                      : Text("Change Server Address"),
                  onPressed: () async {
                    final uri = await showUriDialog(
                      context,
                      "API Server Address",
                      login.serverUrl == null
                          ? null
                          : Uri.tryParse(login.serverUrl),
                      !kReleaseMode,
                    );
                    debugPrint(uri.toString());
                    if (uri != null) {
                      if (uri.authority.isEmpty) {
                        login.setServerUrl(null);
                      } else {
                        login.setServerUrl(uri);
                      }
                    }
                  },
                ),
              if (!kReleaseMode)
                RaisedButton(
                  child: Text("Log in with Session ID"),
                  onPressed: () {
                    _logInWithSessionId(context);
                  },
                ),
              GoogleSignInButton(
                onPressed: Core.login(context).serverUrl?.isEmpty ?? true
                    ? null
                    : () {
                        _logInWithGoogle(context);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
