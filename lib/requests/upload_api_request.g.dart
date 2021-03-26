// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_api_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadApiRequestAdapter extends TypeAdapter<UploadApiRequest> {
  @override
  final int typeId = 2;

  @override
  UploadApiRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadApiRequest(
      fields[1] as String,
      fields[2] as String,
      fields[3] as Uint8List,
      fields[5] as String,
      method: fields[0] as String,
      fileFieldName: fields[4] as String,
      formFields: (fields[6] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UploadApiRequest obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.method)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.contents)
      ..writeByte(4)
      ..write(obj.fileFieldName)
      ..writeByte(5)
      ..write(obj.fileName)
      ..writeByte(6)
      ..write(obj.formFields);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadApiRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
