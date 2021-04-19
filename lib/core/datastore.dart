part of 'api.dart';

const _boxNameDatastoreMetadata = 'datastoreMetadata';

abstract class Datastore<D extends Datastore<D, S, T>, S extends ApiSession,
    T extends ApiCubit<D, S, T>> {
  late final T api;
  late final Box _metadataBox;
  Completer<void> _readyCompleter = Completer();
  Future<void> get ready => _readyCompleter.future;

  Datastore();

  @protected
  E? getMetadata<E>(String key, {E? defaultValue}) {
    return _metadataBox.get(key, defaultValue: defaultValue);
  }

  @protected
  Future<void> putMetadata<E>(String key, E value) {
    return _metadataBox.put(key, value);
  }

  Future<void> _initialize(T api) async {
    if (_readyCompleter.isCompleted) return;
    debugPrint('[datastore] Initializing');
    this.api = api;

    _metadataBox = await Hive.openBox(_boxNameDatastoreMetadata);

    initialize();

    debugPrint('[datastore] Ready');
    _readyCompleter.complete();
  }

  @protected
  Future<void> wipe() async {
    await ready;
    debugPrint('[datastore] Clearing');

    _readyCompleter = Completer<void>();
    _metadataBox.clear();
    clearData();

    debugPrint('[datastore] Clearing Done');
    _readyCompleter.complete();
  }

  Future<void> initialize();

  Future<void> clearData();

  Future<void> parseData(Map<String, dynamic> data);
}
