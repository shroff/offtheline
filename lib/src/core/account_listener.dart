import 'dart:async';

import 'package:meta/meta.dart';

import 'account.dart';
import 'api_client.dart';

mixin AccountListener<T, R extends ApiResponse<T>> {
  late final Account<T, R> _account;
  @protected
  Account<T, R> get account => _account;

  bool _closed = false;
  @protected
  bool get closed => _closed;

  @mustCallSuper
  FutureOr<void> initialize(Account<T, R> account) {
    _account = account;
  }

  @mustCallSuper
  FutureOr<void> delete() {
    _closed = true;
  }
}
