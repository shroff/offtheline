import 'item_processor.dart';

Future<Map<K, R>> processItems<K, T, R>(
  SingleItemProcessor<T, R> processItem,
  bool useIsolateIfAvailable,
  Map<K, T> items,
) async {
  final result = <K, R>{};
  for (final entry in items.entries) {
    // debug.log('Processing ${entry.key}');
    result[entry.key] = await processItem(
      entry.value
    );
  }
  return result;
}
