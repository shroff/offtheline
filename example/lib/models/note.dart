import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 1)
class Note with HiveObjectMixin {
  @HiveField(0)
  DateTime creationTime;

  @HiveField(1)
  DateTime updateTime;

  @HiveField(2)
  String title;

  @HiveField(4)
  String? color;

  @HiveField(3)
  String? details;

  @HiveField(5)
  bool starred;

  @HiveField(6)
  bool archived;

  Note({
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
