import 'package:example/api/actions/edit_note_action.dart';
import 'package:example/api/api.dart';
import 'package:example/models/note.dart';
import 'package:example/pages/notes/multiselect_manager.dart';
import 'package:example/pages/notes/view_prefs.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

class NotesList extends StatefulWidget {
  const NotesList({Key? key}) : super(key: key);

  @override
  State<NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  Stream<List<Note>>? stream;

  @override
  void initState() {
    super.initState();
    context.read<ViewPrefsManager>().addListener((state) {
      refilter(state);
    }, fireImmediately: true);
  }

  void refilter(ViewPrefs viewPrefs) {
    final stream = context
        .read<ExampleAccount>()
        .datastore
        .isar
        .notes
        .filter()
        .optional(!viewPrefs.showArchived, (q) => q.archivedEqualTo(false))
        .sortByStarredDesc()
        .thenByCreationTime()
        .build()
        .watch(initialReturn: true);
    setState(() {
      this.stream = stream;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<Set<int>>();
    final account = context.read<ExampleAccount>();
    bool selecting = selection.isNotEmpty;

    return StreamBuilder(
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
                                      .toggle(note.id);
                                }
                              : () {
                                  account.addAction(EditNoteAction(
                                    note: note,
                                    starred: !note.starred,
                                  ));
                                },
                          selected: selection.contains(note.id),
                          onLongPress: selecting
                              ? null
                              : () {
                                  context
                                      .read<MultiSelectManager>()
                                      .toggle(note.id);
                                },
                          subtitle:
                              note.details.isEmpty ? null : Text(note.details),
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
    );
  }
}
