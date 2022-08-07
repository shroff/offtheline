import 'package:example/api/api.dart';
import 'package:example/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ApiActionTypeAdapter(actionDeserializers));

  final domainManger = await ExampleDomainManager.create();
  runApp(MyApp(
    domainManager: domainManger,
  ));
}

class MyApp extends StatelessWidget {
  final ExampleDomainManager domainManager;

  final _loginAppKey = UniqueKey();

  MyApp({Key? key, required this.domainManager}) : super(key: key);

  @override
  Widget build(BuildContext context) => StateNotifierProvider.value(
        value: domainManager,
        builder: (context, child) {
          debugPrint('Building Main');
          final domainManager = context.watch<ExampleDomainManager>();

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
