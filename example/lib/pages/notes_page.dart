import 'dart:math';

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
      floatingActionButton: FloatingActionButton(onPressed: () {
        context
            .read<ExampleDomain>()
            .datastore
            .isar
            .writeTxn((isar) => isar.notes.put(Note(
                  id: null,
                  creationTime: DateTime.now(),
                  updateTime: DateTime.now(),
                  title: 'Note Title ${Random().nextInt(42)}',
                  color: null,
                  details: null,
                  starred: false,
                  archived: false,
                )));
      }),
      body: StreamBuilder(
        builder: (context, snapshot) => ConstrainedBox(
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
                        subtitle:
                            note.details == null ? null : Text(note.details!),
                        trailing: note.starred ? const Icon(Icons.star) : null,
                      )
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        stream: stream,
      ),
    );
  }
}
