import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'api/actions/deserializers.dart';
import 'api/api.dart';
import 'api/user_agent.dart';
import 'app.dart';
import 'pages/login_page.dart';

void main() async {
  OTL.logger = Logger();
  await Hive.initFlutter();
  Hive.registerAdapter(ApiActionTypeAdapter(actionDeserializers));

  await initilizeUserAgent();
  final domainManger = await DomainManager.create<ExampleDomain>(
    (domainId) => ExampleDomain.open(domainId, clear: false),
  );
  runApp(MyApp(
    domainManager: domainManger,
  ));
}

class MyApp extends StatelessWidget {
  final DomainManager<ExampleDomain> domainManager;

  final _loginAppKey = UniqueKey();

  MyApp({Key? key, required this.domainManager}) : super(key: key);

  @override
  Widget build(BuildContext context) => StateNotifierProvider<
          DomainManager<ExampleDomain>,
          DomainManagerState<ExampleDomain>>.value(
        value: domainManager,
        builder: (context, child) {
          debugPrint('Building Main');
          final domainManager =
              context.watch<DomainManagerState<ExampleDomain>>();

          final domain = domainManager.currentDomain;
          if (domain == null) {
            return buildLoginPage(context);
          }
          return ExampleApp(key: ValueKey(domain.id), domainId: domain.id);
        },
      );

  Widget buildLoginPage(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        key: _loginAppKey,
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
