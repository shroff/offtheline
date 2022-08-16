import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'api/actions/deserializers.dart';
import 'api/api.dart';
import 'app.dart';
import 'pages/login_page.dart';

void main() async {
  OTL.logger = Logger();
  await Hive.initFlutter();
  Hive.registerAdapter(ApiActionTypeAdapter(actionDeserializers));

  await Api.initilizeUserAgent();
  final accountManager = await AccountManager.restore<ExampleAccount>(
    (accountId) => ExampleAccount.open(accountId, clear: false),
  );
  runApp(AccountSelector(
    accountManager: accountManager,
  ));
}

class AccountSelector extends StatelessWidget {
  final AccountManager<ExampleAccount> accountManager;
  final _loginAppKey = UniqueKey();

  AccountSelector({Key? key, required this.accountManager}) : super(key: key);

  @override
  Widget build(BuildContext context) => StateNotifierProvider<
          AccountManager<ExampleAccount>,
          AccountManagerState<ExampleAccount>>.value(
        value: accountManager,
        builder: (context, child) {
          final account = context.select<AccountManagerState<ExampleAccount>,
              ExampleAccount?>((state) => state.selectedAccount);

          return account == null
              ? _LoginApp(key: _loginAppKey)
              : ExampleApp(key: ValueKey(account.id), accountId: account.id);
        },
      );
}

class _LoginApp extends StatelessWidget {
  const _LoginApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OffTheLine Example Login',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const LoginPage(),
          );
        },
      );
}
