import 'add_note_action.dart';
import 'edit_note_action.dart';

const actionDeserializers = {
  AddNoteAction.actionName: AddNoteAction.deserialize,
  EditNoteAction.actionName: EditNoteAction.deserialize,
};
