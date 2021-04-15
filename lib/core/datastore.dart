import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'api_cubit.dart';

const _boxNameDatastoreMetadata = 'datastoreMetadata';
const _metadataKeySchemaVersion = 'schemaVersion';

abstract class Datastore<I, D extends Datastore<I, D, S, T>,
    S extends ApiSession, T extends ApiCubit<I, D, S, T>> {
  late final T api;
  late Box _metadataBox;
  Completer<void> _readyCompleter = Completer();
  Future<void> get ready => _readyCompleter.future;

  int get schemaVersion;

  Datastore();

  E? getMetadata<E>(String key, {E? defaultValue}) {
    return _metadataBox.get(key, defaultValue: defaultValue);
  }

  Future<void> putMetadata<E>(String key, E value) {
    return _metadataBox.put(key, value);
  }

  @mustCallSuper
  Future<void> initialize(T api) async {
    if (_readyCompleter.isCompleted) return;
    debugPrint('[datastore] Initializing');
    this.api = api;

    await _openBoxes();

    debugPrint('[datastore] Ready');
    _readyCompleter.complete();
  }

  Future<I?> generateId();

  Future<void> openBoxes();

  Future<void> deleteBoxes();

  Future<void> _openBoxes({bool clear = false}) async {
    try {
      _metadataBox = await Hive.openBox(_boxNameDatastoreMetadata);
      if (clear ||
          getMetadata(_metadataKeySchemaVersion, defaultValue: 0) !=
              schemaVersion) {
        await deleteBoxes();
        await putMetadata(_metadataKeySchemaVersion, schemaVersion);
      }
      await openBoxes();
    } catch (e) {
      // TODO #silentfail
      debugPrint(e.toString());
    }
  }

  Future<void> wipe() async {
    await ready;
    debugPrint('[datastore] Clearing');

    _readyCompleter = Completer<void>();
    if (kIsWeb) {
      await _metadataBox.clear();
    } else {
      await _metadataBox.deleteFromDisk();
      _metadataBox = await Hive.openBox(_boxNameDatastoreMetadata);
    }
    await _openBoxes(clear: true);

    debugPrint('[datastore] Clearing Done');
    _readyCompleter.complete();
  }

  Future<void> parseData(Map<String, dynamic> data);
}
