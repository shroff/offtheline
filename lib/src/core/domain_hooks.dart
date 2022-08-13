import 'dart:async';

import 'package:meta/meta.dart';

import 'domain.dart';

mixin DomainHooks<R> {
  late final Account<R> _account;
  @protected
  Account<R> get account => _account;

  bool _closed = false;
  @protected
  bool get closed => _closed;

  @mustCallSuper
  FutureOr<void> initialize(Account<R> account) {
    _account = account;
  }

  @mustCallSuper
  FutureOr<void> close() {
    _closed = true;
  }
}
