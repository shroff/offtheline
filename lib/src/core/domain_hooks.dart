import 'dart:async';

import 'package:flutter/foundation.dart';

import 'domain.dart';

mixin DomainHooks<R> {
  late final Domain<R> _domain;
  @protected
  Domain<R> get domain => _domain;

  bool _closed = false;
  @protected
  bool get closed => _closed;

  @mustCallSuper
  FutureOr<void> initialize(Domain<R> domain) {
    _domain = domain;
  }

  @mustCallSuper
  FutureOr<void> close() {
    _closed = true;
  }
}
