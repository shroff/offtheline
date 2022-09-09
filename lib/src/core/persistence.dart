import 'dart:async';

import 'package:hive/hive.dart';

import 'global.dart';

class AccountPersistence {
  final String id;
  final bool clear;
  final List<Box> openBoxes = [];
  late final Box _persist;

  final _initializationCompleter = Completer();
  Future get initialized => _initializationCompleter.future;

  AccountPersistence({required this.id, this.clear = false}) {
    openBox('persist').then((box) async {
      if (clear) {
        OTL.logger
            ?.i('[account][$id] Clearing ${box.values.length} stale entries');
        await box.clear();
      }
      _persist = box;
      _initializationCompleter.complete();
    });
  }

  E? getPersisted<E>(String key) {
    return _persist.get(key);
  }

  Future<void> persist<E>(String key, E value) {
    if (value == null) {
      return _persist.delete(key).then((value) => _persist.flush());
    } else {
      return _persist.put(key, value).then((value) => _persist.flush());
    }
  }

  Future<Box<T>> openBox<T>(String name) async {
    final box = await Hive.openBox<T>('$id-$name');
    if (clear) {
      await box.clear();
    }
    openBoxes.add(box);
    return box;
  }

  Stream<BoxEvent> watchMetadata({dynamic key}) {
    return _persist.watch(key: key);
  }

  Future<void> delete() async {
    for (final box in openBoxes) {
      await box.close();
      await Hive.deleteBoxFromDisk(box.name);
    }
  }
}
