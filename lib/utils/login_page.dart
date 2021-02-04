import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage<T extends ApiCubit> extends StatelessWidget {
  final googleClientId;
  const LoginPage({Key key, @required this.googleClientId}) : super(key: key);

  void _logInWithSessionId(BuildContext context) async {
    final apiCubit = context.read<T>();
    if (!apiCubit.canLogIn) {
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
    String response = await apiCubit.loginWithSessionId(sessionId);
    _handleLoginResponse(response, context);
  }

  void _logInWithGoogle(BuildContext context) async {
    final apiCubit = context.read<T>();
    if (!apiCubit.canLogIn) {
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
    String response = await apiCubit.loginWithGoogle(user.email, idToken);
    _handleLoginResponse(response, context);
  }

  void _handleLoginResponse(String response, BuildContext context) async {
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
            TextButton(
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: FixedPageBody(
        child: Center(
          child: BlocBuilder<T, ApiState>(
            buildWhen: (oldState, newState) {
              return oldState.baseApiUrl != newState.baseApiUrl;
            },
            builder: (context, state) {
              final apiCubit = context.read<T>();
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (apiCubit.canChangeBaseApiUrl)
                    TextButton(
                      child: state.baseApiUrl == null
                          ? Text('Set Server Address')
                          : Text("Change Server Address"),
                      onPressed: () async {
                        final uri = await showUriDialog(
                          context,
                          title: "API Server Address",
                          preset: state.baseApiUrl,
                          allowHttp: !kReleaseMode,
                        );
                        debugPrint(uri.toString());
                        if (uri != null) {
                          apiCubit.baseApiUrl = uri;
                        }
                      },
                    ),
                  if (!kReleaseMode)
                    ElevatedButton(
                      child: Text("Log in with Session ID"),
                      onPressed: apiCubit.canLogIn
                          ? () {
                              _logInWithSessionId(context);
                            }
                          : null,
                    ),
                  GoogleSignInButton(
                    onPressed: apiCubit.canLogIn
                        ? () {
                            _logInWithGoogle(context);
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
