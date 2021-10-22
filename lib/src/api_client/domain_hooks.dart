part of 'api_client.dart';

mixin DomainHooks<R> {
  late final Domain<R> _domain;
  @protected
  Domain<R> get domain => _domain;
  bool _closed = false;

  @mustCallSuper
  FutureOr<void> initialize(Domain<R> domain) {
    _domain = domain;
  }

  @mustCallSuper
  FutureOr<void> close() {
    _closed = true;
  }
}
