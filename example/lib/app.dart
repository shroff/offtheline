import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:example/api/api.dart';

import 'pages/notes/notes_page.dart';

Map<String, Widget Function(BuildContext)> _pageBuilders = {
  '/': (context) => const NotesPage(),
};

Map<String, Route<dynamic> Function(RouteSettings)> _routeBuilders = {};

class ExampleApp extends StatelessWidget {
  final String accountId;

  const ExampleApp({Key? key, required this.accountId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final account =
        context.select<AccountManagerState<ExampleAccount>, ExampleAccount?>(
            (state) => state.accounts[accountId]);
    if (account == null) return Container();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: account),
      ],
      child: const _WelcomeAppContent(),
    );
  }
}

class _WelcomeAppContent extends StatefulWidget {
  const _WelcomeAppContent({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WelcomeAppState();
}

class _WelcomeAppState extends State<_WelcomeAppContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OffTheLine Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (_pageBuilders.containsKey(settings.name)) {
          return MaterialPageRoute<Object>(
            settings: settings,
            builder: _pageBuilders[settings.name!]!,
          );
        }
        return _routeBuilders[settings.name!]?.call(settings);
      },
    );
  }
}
