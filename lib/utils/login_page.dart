import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/core/datastore.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

typedef AuthRequestBuilder = Future<Request?> Function(
    BuildContext, UriBuilder);

class LoginPage<I, D extends Datastore<I, D, S, T>, S extends ApiSession,
    T extends ApiCubit<I, D, S, T>> extends StatelessWidget {
  final AuthRequestBuilder? buildSessionIdAuthRequest;
  final AuthRequestBuilder? buildEmailAuthRequest;
  final AuthRequestBuilder? buildGoogleAuthRequest;

  const LoginPage({
    Key? key,
    this.buildSessionIdAuthRequest,
    this.buildEmailAuthRequest,
    this.buildGoogleAuthRequest,
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
      await api.stream.firstWhere((state) => state.ready);
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
    final request = await buildAuthRequest(context, api.createUriBuilder(''));
    if (request == null) {
      Navigator.of(context).pop();
      return;
    }
    final response = await api.sendRequest(request, authRequired: false);
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
                      child: Text("Change Server Address"),
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
                              _performLogin(
                                  context, buildSessionIdAuthRequest!);
                            }
                          : null,
                    ),
                  if (buildEmailAuthRequest != null)
                    ElevatedButton(
                      child: Text("Log in with Email"),
                      onPressed: api.canLogIn
                          ? () {
                              _performLogin(context, buildEmailAuthRequest!);
                            }
                          : null,
                    ),
                  if (buildGoogleAuthRequest != null)
                    GoogleAuthButton(
                      onPressed: api.canLogIn
                          ? () {
                              _performLogin(context, buildGoogleAuthRequest!);
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
