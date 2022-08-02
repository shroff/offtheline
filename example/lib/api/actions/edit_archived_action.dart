import 'dart:async';

import 'package:example/api/api.dart';
import 'package:example/models/note.dart';

class EditArchivedAction extends ApiAction<ExampleDomain> with JsonApiAction {
  static const String actionName = 'editArchived';

  final int noteId;
  final bool archived;

  EditArchivedAction({required this.noteId, required this.archived});

  @override
  String get name => actionName;
  @override
  String get method => 'put';
  @override
  String get endpoint => '/notes/$noteId';

  @override
  String generateDescription(ExampleDomain domain) {
    final note = domain.datastore.isar.notes.getSync(noteId);
    return '${archived ? 'Archiving' : 'Unarchiving'} start for ${note?.title}';
  }

  @override
  FutureOr<void> applyOptimisticUpdate(ExampleDomain domain) {
    domain.datastore.isar.writeTxn((isar) async {
      final note = await domain.datastore.isar.notes.get(noteId);
      if (note != null) {
        note.archived = archived;
        isar.notes.put(note);
      }
    });
  }

  @override
  FutureOr<void> revertOptimisticUpdate(ExampleDomain domain) {
    domain.datastore.isar.writeTxn((isar) async {
      final note = await domain.datastore.isar.notes.get(noteId);
      if (note != null) {
        note.archived = !archived;
        isar.notes.put(note);
      }
    });
  }

  @override
  Map<String, dynamic>? generateRequestBody() => {'archived': archived};

  @override
  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'archived': archived,
      };

  static EditArchivedAction deserialize(
          Map<String, dynamic> map, dynamic data) =>
      EditArchivedAction(
        noteId: map['noteId'],
        archived: map['archived'],
      );
}
