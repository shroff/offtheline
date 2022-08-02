import 'package:example/models/note.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path_provider/path_provider.dart';

class ExampleDatastore with DomainHooks<Map<String, dynamic>> {
  late final Isar isar;

  @override
  Future<void> initialize(Domain<Map<String, dynamic>> domain) async {
    super.initialize(domain);

    final dir = kIsWeb ? null : await getApplicationSupportDirectory();

    isar = await Isar.open(
      schemas: [NoteSchema],
      directory: dir?.path,
    );

    domain.api.addResponseProcessor(processResponse);
  }

  @override
  Future<void> close() async {
    super.close();
    await isar.close();
  }

  Future<void> processResponse(Map<String, dynamic>? data, dynamic tag) async {
    if (data == null) return;

    if (tag == 'all-notes') {
      final list = (data['notes'] as List).cast<Map<String, dynamic>>();
      await isar.notes.clear();
      isar.writeTxn((isar) => isar.notes
          .putAll(list.map((e) => Note.fromMap(e)).toList(growable: false)));
    }
  }
}
