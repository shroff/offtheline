import 'dart:async';

import 'package:example/api/api.dart';
import 'package:example/models/note.dart';

class EditNoteAction extends ApiAction<ExampleAccount> with JsonApiAction {
  static const String actionName = 'editNote';

  final int noteId;
  final String? title;
  final String? oldTitle;
  final String? details;
  final String? oldDetails;
  final bool updateColor;
  final String? color;
  final String? oldColor;
  final bool? starred;
  final bool? oldStarred;
  final bool? archived;
  final bool? oldArchived;

  EditNoteAction._({
    required this.noteId,
    this.title,
    this.oldTitle,
    this.details,
    this.oldDetails,
    this.updateColor = false,
    this.color,
    this.oldColor,
    this.starred,
    this.oldStarred,
    this.archived,
    this.oldArchived,
  });

  factory EditNoteAction({
    required Note note,
    String? title,
    String? details,
    bool updateColor = false,
    String? color,
    bool? starred,
    bool? archived,
  }) {
    return EditNoteAction._(
      noteId: note.id,
      title: (title == note.title) ? null : title,
      oldTitle: (title == note.title) ? null : note.title,
      details: (details == note.details) ? null : details,
      oldDetails: (details == note.details) ? null : note.details,
      updateColor: updateColor,
      color: (color == note.color) ? null : color,
      oldColor: (color == note.color) ? null : note.color,
      starred: starred,
      oldStarred: starred == null ? null : note.starred,
      archived: archived,
      oldArchived: archived == null ? null : note.archived,
    );
  }

  factory EditNoteAction.star({required int noteId, required bool starred}) {
    return EditNoteAction._(
      noteId: noteId,
      starred: starred,
      oldStarred: !starred,
    );
  }

  factory EditNoteAction.archive(
      {required int noteId, required bool archived}) {
    return EditNoteAction._(
      noteId: noteId,
      archived: archived,
      oldArchived: !archived,
    );
  }

  @override
  String get name => actionName;
  @override
  String get method => 'put';
  @override
  String get endpoint => '/notes/$noteId';

  @override
  String generateDescription(ExampleAccount account) {
    return 'Editing note $noteId';
  }

  @override
  Future<void> applyOptimisticUpdate(ExampleAccount account) async {
    final isar = account.datastore.isar;
    final note = await isar.notes.get(noteId);
    if (note == null) {
      return;
    }
    if (title != null) {
      note.title = title!;
    }
    if (details != null) {
      note.details = details!;
    }
    if (updateColor) {
      note.color = color;
    }
    if (starred != null) {
      note.starred = starred!;
    }
    if (archived != null) {
      note.archived = archived!;
    }

    return isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }

  @override
  Future<void> revertOptimisticUpdate(ExampleAccount account) async {
    final isar = account.datastore.isar;
    final note = await isar.notes.get(noteId);
    if (note == null) {
      return;
    }
    if (oldTitle != null) {
      note.title = oldTitle!;
    }
    if (oldDetails != null) {
      note.details = oldDetails!;
    }
    if (updateColor) {
      note.color = oldColor;
    }
    if (oldStarred != null) {
      note.starred = oldStarred!;
    }
    if (oldArchived != null) {
      note.archived = oldArchived!;
    }

    return isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    final body = <String, dynamic>{
      'id': noteId,
    };
    if (title != null) {
      body['title'] = title;
    }
    if (details != null) {
      body['details'] = details;
    }
    if (updateColor) {
      body['color'] = color;
    }
    if (starred != null) {
      body['starred'] = starred;
    }
    if (archived != null) {
      body['archived'] = archived;
    }
    return body;
  }

  @override
  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'title': title,
        'oldTitle': oldTitle,
        'details': details,
        'oldDetails': oldDetails,
        'updateColor': updateColor,
        'color': color,
        'oldColor': oldColor,
        'starred': starred,
        'oldStarred': oldStarred,
        'archived': archived,
        'oldArchived': oldArchived,
      };

  static EditNoteAction deserialize(Map<String, dynamic> map, dynamic data) =>
      EditNoteAction._(
        noteId: map['noteId'],
        title: map['title'],
        oldTitle: map['oldTitle'],
        details: map['details'],
        oldDetails: map['oldDetails'],
        updateColor: map['updateColor'],
        color: map['color'],
        oldColor: map['oldColor'],
        starred: map['starred'],
        oldStarred: map['oldStarred'],
        archived: map['archived'],
        oldArchived: map['oldArchived'],
      );
}
