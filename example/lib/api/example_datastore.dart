import 'package:example/models/note.dart';
import 'package:isar/isar.dart';
import 'package:offtheline/offtheline.dart';

class ExampleDatastore with DomainHooks<Map<String, dynamic>> {
  late final Isar isar;
  late final void Function() removeResponseProcessor;

  @override
  Future<void> initialize(Domain<Map<String, dynamic>> domain) async {
    super.initialize(domain);

    isar = await Isar.open(
      [NoteSchema],
      name: domain.id,
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
      isar.writeTxn(() async {
        await isar.notes.clear();
        return isar.notes.putAll(notes);
      });
    }
  }
}
