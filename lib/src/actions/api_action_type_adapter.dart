import 'package:hive/hive.dart';

import 'error_action.dart';
import 'api_action.dart';
import '../core/account.dart';

const _fieldName = 0;
const _fieldProps = 1;
const _fieldBinaryData = 2;

typedef ApiActionDeserializer<A extends Account> = ApiAction<A> Function(Map<String, dynamic> props, dynamic data);

class ApiActionTypeAdapter<A extends Account> extends TypeAdapter<ApiAction<A>> {
  final Map<String, ApiActionDeserializer<A>> deserializers;
  @override
  final int typeId;

  ApiActionTypeAdapter(
    this.deserializers, {
    this.typeId = 0,
  });

  @override
  ApiAction<A> read(BinaryReader reader) {
    int n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    final name = fields[_fieldName];
    final deserializer = deserializers[name];
    final props = (fields[_fieldProps] as Map).cast<String, dynamic>();
    final data = fields[_fieldBinaryData];
    if (deserializer == null) {
      return ErrorAction<A>(
        name: name,
        error: 'Unknown Action',
        props: props,
        binaryData: data,
      );
    }
    try {
      return deserializer.call(props, data);
    } catch (e) {
      return ErrorAction<A>(
        name: name,
        error: e.toString(),
        props: props,
        binaryData: data,
      );
    }
  }

  @override
  void write(BinaryWriter writer, ApiAction<A> obj) {
    writer.writeByte(3);
    writer.writeByte(_fieldName);
    writer.write(obj.name);
    writer.writeByte(_fieldProps);
    writer.write(obj.toMap());
    writer.writeByte(_fieldBinaryData);
    writer.write(obj.binaryData);
  }
}
