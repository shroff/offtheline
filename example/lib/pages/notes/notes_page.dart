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

class NotesPageContent extends StatefulWidget {
  const NotesPageContent({Key? key}) : super(key: key);

  @override
  State<NotesPageContent> createState() => _NotesPageContentState();
}

class _NotesPageContentState extends State<NotesPageContent> {
  @override
  Widget build(BuildContext context) {
    final viewPrefs = context.watch<ViewPrefs>();
    final selection = context.watch<Set<int>>();
    bool selecting = selection.isNotEmpty;

    final domain = context.read<ExampleDomain>();
    final stream = domain.datastore.isar.notes
        .filter()
        .optional(!viewPrefs.showArchived, (q) => q.archivedEqualTo(false))
        .sortByStarredDesc()
        .thenByCreationTime()
        .build()
        .watch(initialReturn: true);

    return Scaffold(
      appBar: buildAppBar(viewPrefs, selection),
      floatingActionButton: const AddNoteButton(),
      body: StreamBuilder(
        key: ValueKey(stream),
        builder: (context, AsyncSnapshot<List<Note>> snapshot) {
          final data = snapshot.data;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: data != null
                  ? ListView(
                      children: [
                        for (final note in data)
                          ListTile(
                            title: Text(note.title),
                            onTap: selecting
                                ? () {
                                    context
                                        .read<MultiSelectManager>()
                                        .toggle(note.id!);
                                  }
                                : () {
                                    domain.addAction(SetStarredAction(
                                      noteId: note.id!,
                                      starred: !note.starred,
                                    ));
                                  },
                            selected: selection.contains(note.id),
                            onLongPress: selecting
                                ? null
                                : () {
                                    context
                                        .read<MultiSelectManager>()
                                        .toggle(note.id!);
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
          );
        },
        stream: stream,
      ),
    );
  }

  AppBar buildAppBar(ViewPrefs viewPrefs, Set<int> selection) {
    bool selecting = selection.isNotEmpty;

    final domain = context.read<ExampleDomain>();
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
              IconButton(
                onPressed: () {
                  context.read<ViewPrefsManager>().showArchived =
                      !viewPrefs.showArchived;
                },
                icon: const Icon(Icons.filter_alt),
              )
            ],
    );
  }
}
