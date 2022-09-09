import 'dart:async';

import 'package:meta/meta.dart';

import 'account.dart';

mixin AccountListener<Datastore> {
  late final Account<Datastore> _account;
  @protected
  Account get account => _account;

  bool _closed = false;
  @protected
  bool get closed => _closed;

  @mustCallSuper
  FutureOr<void> initialize(Account<Datastore> account) {
    _account = account;
  }

  @mustCallSuper
  FutureOr<void> delete() {
    _closed = true;
  }
}
