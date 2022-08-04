import 'dart:math';

import 'package:example/api/actions/add_note_action.dart';
import 'package:example/api/actions/set_starred_action.dart';
import 'package:example/api/api.dart';
import 'package:example/models/note.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hideArchived = false;
    bool showOnlyStarred = false;
    final stream = context
        .read<ExampleDomain>()
        .datastore
        .isar
        .notes
        .filter()
        .optional(hideArchived, (q) => q.archivedEqualTo(false))
        .optional(showOnlyStarred, (q) => q.starredEqualTo(true))
        .sortByStarredDesc()
        .thenByCreationTime()
        .build()
        .watch(initialReturn: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final domain = context.read<ExampleDomain>();
          final draft = await showNewNoteDialog();
          if (draft == null) {
            return;
          }
          domain.addAction(AddNoteAction(
            noteId: await domain.generateId(),
            title: draft.title,
            color: null,
            details: draft.details,
          ));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        builder: (context, snapshot) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: snapshot.hasData
                ? ListView(
                    children: [
                      for (final note in snapshot.data as List<Note>)
                        ListTile(
                          title: Text('${note.id} - ${note.title}'),
                          onTap: () {
                            context
                                .read<ExampleDomain>()
                                .addAction(SetStarredAction(
                                  noteId: note.id!,
                                  starred: !note.starred,
                                ));
                          },
                          subtitle: note.details?.isEmpty ?? true
                              ? null
                              : Text(note.details!),
                          trailing:
                              note.starred ? const Icon(Icons.star) : null,
                        )
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        stream: stream,
      ),
    );
  }

  Future<NoteDraft?> showNewNoteDialog() async {
    String title = '';
    String details = '';
    return showDialog<NoteDraft>(
      context: context,
      builder: (conext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.0),
                ),
                onChanged: (value) {
                  setState(() => title = value);
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Details...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.0),
                ),
                minLines: 5,
                maxLines: 8,
                onChanged: (value) {
                  details = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: title.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(NoteDraft(title, details)),
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}

class NoteDraft {
  final String title;
  final String details;

  NoteDraft(this.title, this.details);
}
