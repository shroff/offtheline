import 'dart:async';

import 'package:example/api/api.dart';
import 'package:example/models/note.dart';

class SetStarredAction extends ApiAction<ExampleDomain> with JsonApiAction {
  static const String actionName = 'setStarred';

  final int noteId;
  final bool starred;

  SetStarredAction({required this.noteId, required this.starred});

  @override
  String get name => actionName;
  @override
  String get method => 'put';
  @override
  String get endpoint => '/notes/$noteId';

  @override
  String generateDescription(ExampleDomain domain) {
    final note = domain.datastore.isar.notes.getSync(noteId);
    return '${starred ? 'Adding' : 'Removing'} start for ${note?.title}';
  }

  @override
  FutureOr<void> applyOptimisticUpdate(ExampleDomain domain) {
    domain.datastore.isar.writeTxn((isar) async {
      final note = await domain.datastore.isar.notes.get(noteId);
      if (note != null) {
        note.starred = starred;
        isar.notes.put(note);
      }
    });
  }

  @override
  FutureOr<void> revertOptimisticUpdate(ExampleDomain domain) {
    domain.datastore.isar.writeTxn((isar) async {
      final note = await domain.datastore.isar.notes.get(noteId);
      if (note != null) {
        note.starred = !starred;
        isar.notes.put(note);
      }
    });
  }

  @override
  Map<String, dynamic>? generateRequestBody() => {'starred': starred};

  @override
  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'starred': starred,
      };

  static SetStarredAction deserialize(Map<String, dynamic> map, dynamic data) =>
      SetStarredAction(
        noteId: map['noteId'],
        starred: map['starred'],
      );
}