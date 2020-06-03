typedef SingleItemProcessor<T, R> = Future<R> Function(T data);

typedef MultiItemProcessor<K, T, R> = Future<Map<K, R>> Function(
  SingleItemProcessor<T, R>,
  bool useIsolateIfAvailable,
  Map<K, T> items,
);