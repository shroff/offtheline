// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_api_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SimpleApiRequestAdapter extends TypeAdapter<SimpleApiRequest> {
  @override
  final int typeId = 1;

  @override
  SimpleApiRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SimpleApiRequest(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      body: fields[4] as dynamic,
      contentType: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SimpleApiRequest obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.method)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.contentType)
      ..writeByte(4)
      ..write(obj.body);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleApiRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
