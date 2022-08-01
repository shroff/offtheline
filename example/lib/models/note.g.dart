// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      creationTime: fields[0] as DateTime,
      updateTime: fields[1] as DateTime,
      title: fields[2] as String,
      color: fields[4] as String?,
      details: fields[3] as String?,
      starred: fields[5] as bool,
      archived: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.creationTime)
      ..writeByte(1)
      ..write(obj.updateTime)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(5)
      ..write(obj.starred)
      ..writeByte(6)
      ..write(obj.archived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
