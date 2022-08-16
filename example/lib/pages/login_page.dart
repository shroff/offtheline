import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'package:example/api/api.dart';

typedef AuthRequestBuilder = Future<Request?> Function(
    BuildContext, UriBuilder);

class LoginPage extends StatefulWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final Client _client = Client();
  Uri? apiBaseUrl = Uri();
  String username = '';

  bool get apiBaseValid =>
      kIsWeb ||
      (apiBaseUrl != null && apiBaseUrl!.hasScheme && apiBaseUrl!.hasAuthority);

  @override
  void initState() {
    super.initState();
  }

  void _performLogin() async {
    final baseUri = UriBuilder.fromUri(apiBaseUrl ?? Uri());
    baseUri.path = '${baseUri.path}/v1/login/email}';
    baseUri.queryParameters['username'] = username;
    final request = Request('post', baseUri.build());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(),
            ),
            Text(
              'Logging In...',
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ],
        ),
      ),
    );
    final accountManager = context.read<AccountManager>();

    try {
      final response = await _client.send(request);
      final responseString = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        if (mounted) {
          Navigator.of(context).pop();
          _showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Login Error',
            message: responseString,
          );
        }
      } else {
        final responseMap =
            (jsonDecode(responseString) as Map).cast<String, dynamic>();
        final account =
            await ExampleAccount.createFromLoginResponse(responseMap);
        account.api.apiBaseUrl = apiBaseUrl ?? Uri();
        accountManager.addAccount(account);
      }
    } on SocketException {
      if (mounted) {
        Navigator.of(context).pop();
        _showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Login Error',
          message: 'Unable to reach server',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Login Error',
          message: e.toString(),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    autocorrect: false,
                    decoration: const InputDecoration(
                      label: Text('Server URL'),
                      hintText: 'https://offtheline.example.com/notes/api',
                    ),
                    onChanged: (value) {
                      setState(() {
                        apiBaseUrl = Uri.tryParse(value);
                      });
                    },
                  ),
                  TextField(
                    autocorrect: false,
                    decoration: const InputDecoration(
                      label: Text('Username'),
                      hintText: 'example',
                    ),
                    onChanged: (value) {
                      username = value;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ElevatedButton(
                      onPressed: _performLogin,
                      child: const Text('Log in'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final accountManager = context.read<AccountManager>();
                      final rid = Random().nextInt(1 << 31);
                      final responseMap = <String, dynamic>{
                        'session': {
                          'domain_id': 'offline-$rid',
                          'user_name': 'user-$rid',
                          'user_display_name': 'Tux',
                          'account_provider_name': 'Offline $rid',
                        },
                        'data': {
                          'notes': [],
                          'id_block': 1,
                        },
                        'config': {
                          'id_block_size': 30,
                        },
                      };
                      final account =
                          await ExampleAccount.createFromLoginResponse(
                        responseMap,
                        useFakeDispatcher: true,
                      );
                      accountManager.addAccount(account);
                    },
                    child: const Text('Log in without server'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showAlertDialog(
    BuildContext context, {
    bool barrierDismissible = false,
    String? title,
    String? message,
    String? negativeText,
    String positiveText = 'OK',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: (title == null) ? null : Text(title),
        content: (message == null)
            ? null
            : Text(
                message,
                softWrap: true,
              ),
        actions: <Widget>[
          if (negativeText != null)
            TextButton(
              child: Text(negativeText),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ElevatedButton(
            child: Text(positiveText),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }
}
