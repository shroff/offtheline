// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simple_api_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SimpleApiRequestAdapter extends TypeAdapter<SimpleApiRequest> {
  @override
  final typeId = 1;

  @override
  SimpleApiRequest read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
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
}
