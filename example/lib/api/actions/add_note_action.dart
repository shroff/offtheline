import 'dart:async';

import 'package:example/api/api.dart';
import 'package:example/models/note.dart';

class AddNoteAction extends ApiAction<ExampleAccount> with JsonApiAction {
  static const String actionName = 'addNote';

  final int noteId;
  final String title;
  final String details;
  final String? color;

  AddNoteAction({
    required this.noteId,
    required this.title,
    required this.details,
    required this.color,
  });

  @override
  String get name => actionName;
  @override
  String get method => 'put';
  @override
  String get endpoint => '/notes/$noteId';

  @override
  String generateDescription(ExampleAccount account) {
    return 'Adding note: $title';
  }

  @override
  FutureOr<void> applyOptimisticUpdate(ExampleAccount account) {
    final timestamp = DateTime.now();
    final isar = account.datastore.isar;
    return isar.writeTxn(() async {
      await isar.notes.put(Note(
        id: noteId,
        creationTime: timestamp,
        updateTime: timestamp,
        title: title,
        details: details,
        color: color,
        starred: false,
        archived: false,
      ));
    });
  }

  @override
  FutureOr<void> revertOptimisticUpdate(ExampleAccount account) {
    final isar = account.datastore.isar;
    return isar.writeTxn(() async {
      await isar.notes.delete(noteId);
    });
  }

  @override
  Map<String, dynamic>? generateRequestBody() => {
        'id': noteId,
        'title': title,
        'details': details,
        'color': color,
      };

  @override
  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'timestamp': DateTime.now(),
        'title': title,
        'details': details,
        'color': color,
      };

  static AddNoteAction deserialize(Map<String, dynamic> map, dynamic data) =>
      AddNoteAction(
        noteId: map['noteId'],
        title: map['title'],
        details: map['details'],
        color: map['color'],
      );
}
