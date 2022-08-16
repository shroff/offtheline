import 'package:example/api/actions/add_note_action.dart';
import 'package:example/api/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddNoteButton extends StatelessWidget {
  const AddNoteButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final account = context.read<ExampleAccount>();
    return FloatingActionButton(
      onPressed: () async {
        final draft = await _showNewNoteDialog(context);
        if (draft == null) {
          return;
        }
        account.addAction(AddNoteAction(
          noteId: await account.generateId(),
          title: draft.title,
          color: null,
          details: draft.details,
        ));
      },
      child: const Icon(Icons.add),
    );
  }

  Future<_NoteDraft?> _showNewNoteDialog(BuildContext context) async {
    String title = '';
    String details = '';
    return showDialog<_NoteDraft>(
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
                  : () => Navigator.of(context).pop(_NoteDraft(title, details)),
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}

class _NoteDraft {
  final String title;
  final String details;

  _NoteDraft(this.title, this.details);
}
