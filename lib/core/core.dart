library core;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appcore/core/api_cubit.dart';
import 'package:appcore/requests/requests.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uri/uri.dart';

import 'core_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'core_browser.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'core_mobile.dart';

part 'api.dart';

part 'login.dart';

BaseClient createCoreHttpClient() => createHttpClient();

class Core<T extends Datastore, U extends LoginUser> extends StatelessWidget {
  final Widget child;
  final UserParser<U> parseUser;
  final T Function() createDatastore;
  final String fixedServerUrl;

  const Core({
    Key key,
    @required this.child,
    @required this.parseUser,
    @required this.createDatastore,
    this.fixedServerUrl,
  }) : super(key: key);

  static Login<U> login<U extends LoginUser>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedLoginWidget>()
        .data;
  }

  static Api api(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedApiWidget>()
        .data;
  }

  static T datastore<T extends Datastore>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedDatastore>()
        .data;
  }

  @override
  Widget build(BuildContext context) =>
      MultiBlocProvider(providers: [
        BlocProvider(create: create)

      ], child: child);

  // @override
  // Widget build(BuildContext context) => _LoginWidget(
  //       parseUser: parseUser,
  //       fixedServerUrl: fixedServerUrl,
  //       child: _DatastoreWidget(
  //         createDatastore: createDatastore,
  //         child: _ApiWidget(
  //           child: child,
  //         ),
  //       ),
  //     );
}
