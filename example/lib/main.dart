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
  final domainManger = await DomainManager.create<ExampleDomain>(
    (domainId) => ExampleDomain.open(domainId, clear: false),
  );
  runApp(DomainSelector(
    domainManager: domainManger,
  ));
}

class DomainSelector extends StatelessWidget {
  final DomainManager<ExampleDomain> domainManager;
  final _loginAppKey = UniqueKey();

  DomainSelector({Key? key, required this.domainManager}) : super(key: key);

  @override
  Widget build(BuildContext context) => StateNotifierProvider<
          DomainManager<ExampleDomain>,
          DomainManagerState<ExampleDomain>>.value(
        value: domainManager,
        builder: (context, child) {
          final domain =
              context.select<DomainManagerState<ExampleDomain>, ExampleDomain?>(
                  (state) => state.currentDomain);

          return domain == null
              ? _LoginApp(key: _loginAppKey)
              : ExampleApp(key: ValueKey(domain.id), domainId: domain.id);
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
