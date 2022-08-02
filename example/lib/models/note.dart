import 'package:isar/isar.dart';

part 'note.g.dart';

@Collection()
class Note {
  @Id()
  int? id;
  DateTime creationTime;
  DateTime updateTime;
  String title;
  String? color;
  String? details;
  bool starred;
  bool archived;

  Note({
    required this.id,
    required this.creationTime,
    required this.updateTime,
    required this.title,
    required this.color,
    required this.details,
    required this.starred,
    required this.archived,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      creationTime: DateTime.parse(map['creationTime']),
      updateTime: DateTime.parse(map['updateTime']),
      title: map['title'] ?? '',
      color: map['color'],
      details: map['detail'],
      starred: map['starred'] == 1,
      archived: map['archived'] == 1,
    );
  }
}
