import 'package:example/models/note.dart';
import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';

const _boxNameNotes = 'notes';

class ExampleDatastore with DomainHooks<Map<String, dynamic>> {
  late final Box<Note> notes;

  @override
  Future<void> initialize(Domain<Map<String, dynamic>> domain) async {
    super.initialize(domain);

    notes = await domain.openBox<Note>(_boxNameNotes);
    domain.api.addResponseProcessor(processResponse);
  }

  @override
  Future<void> close() async {
    super.close();
    await notes.close();
  }

  Future<void> processResponse(Map<String, dynamic>? data, dynamic tag) async {
    if (data == null) return;

    if (tag == 'all-notes') {
      final list = (data['notes'] as List).cast<Map<String, dynamic>>();
      notes.clear();
      for (final map in list) {
        notes.add(Note.fromMap(map));
      }
    }
  }
}
