import 'package:example/models/note.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path_provider/path_provider.dart';

class ExampleDatastore with DomainHooks<Map<String, dynamic>> {
  late final Isar isar;
  late final void Function() removeResponseProcessor;

  @override
  Future<void> initialize(Domain<Map<String, dynamic>> domain) async {
    super.initialize(domain);

    final dir = kIsWeb ? null : await getApplicationSupportDirectory();

    isar = await Isar.open(
      schemas: [NoteSchema],
      directory: dir?.path,
    );

    removeResponseProcessor = domain.api.addResponseProcessor(processResponse);
  }

  @override
  Future<void> close() async {
    super.close();
    removeResponseProcessor();
    await isar.close();
  }

  Future<void> processResponse(Map<String, dynamic>? data, dynamic tag) async {
    if (data == null) return;

    if (data.containsKey('notes')) {
      final list = (data['notes'] as List).cast<Map<String, dynamic>>();
      final notes = list.map((e) => Note.fromMap(e)).toList(growable: false);
      isar.writeTxn((isar) async {
        await isar.notes.clear();
        return isar.notes.putAll(notes);
      });
    }
  }
}
