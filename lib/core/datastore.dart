import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

const _boxNameDatastoreMetadata = 'datastoreMetadata';
const _metadataKeySchemaVersion = 'schemaVersion';

abstract class Datastore {
  var _completer = Completer<void>();

  Future<void> get initialized => _completer.future;
  bool get isInitialized => _completer.isCompleted;

  Box _metadataBox;

  int get schemaVersion;

  E getMetadata<E>(String key, {E defaultValue}) {
    return _metadataBox.get(key, defaultValue: defaultValue);
  }

  Future<void> putMetadata<E>(String key, E value) {
    return _metadataBox.put(key, value);
  }

  Future<void> initialize() async {
    debugPrint('[datastore] Initializing');
    registerTypeAdapters();

    await _openBoxes();

    debugPrint('[datastore] Ready');
    _completer.complete();
  }

  void registerTypeAdapters();

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

  Future<void> clear() async {
    await initialized;
    debugPrint('[datastore] Clearing');

    _completer = Completer<void>();
    await _metadataBox.deleteFromDisk();
    _metadataBox = await Hive.openBox(_boxNameDatastoreMetadata);
    await _openBoxes(clear: true);

    debugPrint('[datastore] Clearing Done');
    _completer.complete();
  }

  Future<void> parseData(Map<String, dynamic> data);
}
