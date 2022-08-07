import 'package:example/api/actions/set_archived_action.dart';
import 'package:example/api/actions/set_starred_action.dart';
import 'package:example/api/api.dart';
import 'package:example/models/note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

import 'add_note_button.dart';
import 'multiselect_manager.dart';
import 'notes_list.dart';
import 'view_prefs.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          StateNotifierProvider<ViewPrefsManager, ViewPrefs>(
            create: (context) => ViewPrefsManager(
              const ViewPrefs(showArchived: false),
            ),
          ),
          StateNotifierProvider<MultiSelectManager, Set<int>>(
            create: (context) => MultiSelectManager(),
          )
        ],
        child: const NotesPageContent(),
      );
}

class NotesPageContent extends StatelessWidget {
  const NotesPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      floatingActionButton: const AddNoteButton(),
      body: const NotesList(),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    final viewPrefs = context.watch<ViewPrefs>();
    final selection = context.watch<Set<int>>();
    final domain = context.read<ExampleDomain>();
    bool selecting = selection.isNotEmpty;

    return AppBar(
      title: selecting
          ? Text('${selection.length} selected')
          : const Text('Notes'),
      leading: selecting
          ? IconButton(
              onPressed: () {
                context.read<MultiSelectManager>().clear();
              },
              icon: const Icon(Icons.close))
          : null,
      actions: selecting
          ? [
              IconButton(
                  onPressed: () {
                    for (final id in selection) {
                      domain.addAction(
                          SetStarredAction(noteId: id, starred: false));
                    }
                    context.read<MultiSelectManager>().clear();
                  },
                  icon: const Icon(Icons.star_outline)),
              IconButton(
                  onPressed: () {
                    for (final id in selection) {
                      domain.addAction(
                          SetStarredAction(noteId: id, starred: true));
                    }
                    context.read<MultiSelectManager>().clear();
                  },
                  icon: const Icon(Icons.star)),
              IconButton(
                  onPressed: () {
                    for (final id in selection) {
                      domain.addAction(
                          SetArchivedAction(noteId: id, archived: true));
                    }
                    context.read<MultiSelectManager>().clear();
                  },
                  icon: const Icon(Icons.archive)),
            ]
          : [
              if (viewPrefs.showArchived)
                IconButton(
                  onPressed: () {
                    context.read<ViewPrefsManager>().showArchived = false;
                  },
                  icon: const Icon(Icons.archive),
                )
              else
                IconButton(
                  onPressed: () {
                    context.read<ViewPrefsManager>().showArchived = true;
                  },
                  icon: const Icon(Icons.archive_outlined),
                )
            ],
    );
  }
}
