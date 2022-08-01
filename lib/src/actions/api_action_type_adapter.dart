import 'package:hive/hive.dart';

import 'unknown_action.dart';
import 'api_action.dart';
import '../core/domain.dart';

const _fieldName = 0;
const _fieldProps = 1;
const _fieldBinaryData = 2;

typedef ApiActionDeserializer<D extends Domain> = ApiAction<D> Function(
    Map<String, dynamic> props, dynamic data);

class ApiActionTypeAdapter<D extends Domain> extends TypeAdapter<ApiAction<D>> {
  final Map<String, ApiActionDeserializer<D>> deserializers;

  ApiActionTypeAdapter(this.deserializers);

  @override
  ApiAction<D> read(BinaryReader reader) {
    int n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    final name = fields[_fieldName];
    final deserializer = deserializers[name];
    final props = (fields[_fieldProps] as Map).cast<String, dynamic>();
    final data = fields[_fieldBinaryData];
    if (deserializer == null) {
      UnknownAction(
        name: name,
        props: props,
        binaryData: data,
      );
    }
    return deserializer!.call(props, data);
  }

  @override
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, ApiAction<D> obj) {
    writer.writeByte(3);
    writer.writeByte(_fieldName);
    writer.write(obj.name);
    writer.writeByte(_fieldProps);
    writer.write(obj.toMap());
    writer.writeByte(_fieldBinaryData);
    writer.write(obj.binaryData);
  }
}
