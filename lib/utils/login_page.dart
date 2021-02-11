import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

typedef AuthRequestBuilder = Future<Request> Function(BuildContext, UriBuilder);

class LoginPage<T extends ApiCubit> extends StatelessWidget {
  final AuthRequestBuilder buildGoogleAuthRequest;
  final AuthRequestBuilder buildSessionIdAuthRequest;

  const LoginPage({
    Key key,
    this.buildGoogleAuthRequest,
    this.buildSessionIdAuthRequest,
  }) : super(key: key);

  void _performLogin(
    BuildContext context,
    AuthRequestBuilder buildAuthRequest,
  ) async {
    final api = context.read<T>();
    if (!api.canLogIn) {
      return;
    }
    // * Make sure we are ready
    while (!api.state.ready) {
      await api.firstWhere((state) => state.ready);
    }
    if (api.isSignedIn) {
      return;
    }

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
    final request =
        await buildAuthRequest(context, api.createUriBuilder(''));
    String response = await api.sendRequest(request, authRequired: false);
    if (response != null) {
      Navigator.of(context).pop();
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
              final api = context.read<T>();
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (api.canChangeBaseApiUrl)
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
                          api.baseApiUrl = uri;
                        }
                      },
                    ),
                  if (buildSessionIdAuthRequest != null)
                    ElevatedButton(
                      child: Text("Log in with Session ID"),
                      onPressed: api.canLogIn
                          ? () {
                              _performLogin(context, buildSessionIdAuthRequest);
                            }
                          : null,
                    ),
                  if (buildGoogleAuthRequest != null)
                    GoogleSignInButton(
                      onPressed: api.canLogIn
                          ? () {
                              _performLogin(context, buildGoogleAuthRequest);
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
