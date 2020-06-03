
abstract class Storage {
  Future<void> initialize();

  Future<String> read({String key});

  Future<void> write({String key, String value});

  Future<void> delete({String key});

  Future<void> deleteAll();
}
