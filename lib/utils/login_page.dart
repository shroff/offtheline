import 'package:appcore/core/api.dart';
import 'package:appcore/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:uri/uri.dart';

typedef AuthRequestBuilder = Future<Request?> Function(
    BuildContext, UriBuilder);

class LoginPage extends StatefulWidget {
  final AuthRequestBuilder? buildSessionIdAuthRequest;
  final AuthRequestBuilder? buildEmailAuthRequest;
  final AuthRequestBuilder? buildGoogleAuthRequest;

  const LoginPage({
    Key? key,
    this.buildSessionIdAuthRequest,
    this.buildEmailAuthRequest,
    this.buildGoogleAuthRequest,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Uri apiBase = Uri();
  bool canChangeApiBase = false;

  bool get apiBaseValid =>
      kIsWeb || (apiBase.hasScheme && apiBase.hasAuthority);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final api = context.read<ApiCubit>();
    apiBase = api.apiBase;
    canChangeApiBase = api.canChangeApiBase;
  }

  void _performLogin(
    BuildContext context,
    AuthRequestBuilder buildAuthRequest,
  ) async {
    final api = context.read<ApiCubit>();

    if (api.state is! ApiStateLoggedOut) {
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
        await buildAuthRequest(context, UriBuilder.fromUri(apiBase));
    if (request == null) {
      Navigator.of(context).pop();
      return;
    }
    final response = await api.login(request, apiBase);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (canChangeApiBase)
                TextButton(
                  child: Text("Change Server Address"),
                  onPressed: () async {
                    final uri = await showUriDialog(
                      context,
                      title: "API Server Address",
                      preset: apiBase,
                      allowHttp: !kReleaseMode,
                    );
                    debugPrint(uri.toString());
                    if (uri != null) {
                      setState(() {
                        apiBase = uri;
                      });
                    }
                  },
                ),
              if (widget.buildSessionIdAuthRequest != null)
                ElevatedButton(
                  child: Text("Log in with Session ID"),
                  onPressed: apiBaseValid
                      ? () {
                          _performLogin(
                              context, widget.buildSessionIdAuthRequest!);
                        }
                      : null,
                ),
              if (widget.buildEmailAuthRequest != null)
                ElevatedButton(
                  child: Text("Log in with Email"),
                  onPressed: apiBaseValid
                      ? () {
                          _performLogin(context, widget.buildEmailAuthRequest!);
                        }
                      : null,
                ),
              if (widget.buildGoogleAuthRequest != null)
                GoogleAuthButton(
                  onPressed: apiBaseValid
                      ? () {
                          _performLogin(
                              context, widget.buildGoogleAuthRequest!);
                        }
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
