
abstract class Storage {
  Future<void> initialize();

  Future<dynamic> read({String key});

  Future<void> write({String key, dynamic value});

  Future<void> delete({String key});

  Future<void> deleteAll();
}
