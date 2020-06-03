library core;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appcore/requests/requests.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'storage.dart';

part 'api.dart';

part 'datastore.dart';

part 'login.dart';

BaseClient createCoreHttpClient() => createHttpClient();

class Core<T extends Datastore> extends StatelessWidget {
  final Logger logger;
  final Widget child;
  final T Function() createDatastore;

  const Core({
    Key key,
    this.logger,
    @required this.child,
    @required this.createDatastore,
  }) : super(key: key);

  static _LoginState login(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedLogin>().data;
  }

  static _ApiState api(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedApi>().data;
  }

  static T datastore<T extends Datastore>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedDatastore>()
        .data;
  }

  @override
  Widget build(BuildContext context) => Login(
        logger: logger,
        child: DatastoreWidget<T>(
          logger: logger,
          createDatastore: createDatastore,
          child: Api(
            logger: logger,
            child: child,
          ),
        ),
      );
}

abstract class Logger {
  void setUserName(String userName);

  void setUserEmail(String userEmail);

  void log(String msg);
}
