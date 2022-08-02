import 'dart:async';

import 'package:example/api/api.dart';
import 'package:example/models/note.dart';

class AddNoteAction extends ApiAction<ExampleDomain> with JsonApiAction {
  static const String actionName = 'addNote';

  final int noteId;
  final DateTime creationTime;
  final DateTime updateTime;
  final String title;
  final String? color;
  final String? details;

  AddNoteAction({
    required this.noteId,
    required this.creationTime,
    required this.updateTime,
    required this.title,
    required this.color,
    required this.details,
  });

  @override
  String get name => actionName;
  @override
  String get method => 'put';
  @override
  String get endpoint => '/notes/$noteId';

  @override
  String generateDescription(ExampleDomain domain) {
    final note = domain.datastore.isar.notes.getSync(noteId);
    return 'Creating note: ${note?.title}';
  }

  @override
  FutureOr<void> applyOptimisticUpdate(ExampleDomain domain) {
    return domain.datastore.isar.writeTxn((isar) async {
      await domain.datastore.isar.notes.put(Note(
        id: noteId,
        creationTime: creationTime,
        updateTime: updateTime,
        title: title,
        color: color,
        details: details,
        starred: false,
        archived: false,
      ));
    });
  }

  @override
  FutureOr<void> revertOptimisticUpdate(ExampleDomain domain) {
    return domain.datastore.isar.writeTxn((isar) async {
      await domain.datastore.isar.notes.delete(noteId);
    });
  }

  @override
  Map<String, dynamic>? generateRequestBody() => {
        'id': noteId,
        'creationTime': creationTime.millisecondsSinceEpoch,
        'updateTime': updateTime.millisecondsSinceEpoch,
        'title': title,
        'color': color,
        'details': details,
      };

  @override
  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'creationTime': creationTime.millisecondsSinceEpoch,
        'updateTime': updateTime.millisecondsSinceEpoch,
        'title': title,
        'color': color,
        'details': details,
      };

  static AddNoteAction deserialize(Map<String, dynamic> map, dynamic data) =>
      AddNoteAction(
        noteId: map['noteId'],
        creationTime: DateTime.fromMillisecondsSinceEpoch(map['creationTime']),
        updateTime: DateTime.fromMillisecondsSinceEpoch(map['updateTime']),
        title: map['title'],
        color: map['color'],
        details: map['details'],
      );
}
