import 'package:example/api/api.dart';
import 'package:example/models/note.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoteDetailsPage extends StatelessWidget {
  final int noteId;
  const NoteDetailsPage({Key? key, required this.noteId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final account = context.read<ExampleAccount>();
    final stream =
        account.datastore.isar.notes.watchObject(noteId, initialReturn: true);
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        final note = snapshot.data as Note;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Note Details'),
            actions: [
              note.starred
                  ? IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.star),
                    )
                  : IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.star_outline),
                    ),
            ],
          ),
        );
      },
    );
  }
}
