import 'package:hive/hive.dart';

import '../core/account.dart';
import '../core/api_client.dart';
import 'api_action.dart';
import 'unknown_action.dart';

const _fieldName = 0;
const _fieldProps = 1;
const _fieldBinaryData = 2;

typedef ApiActionDeserializer<R extends ApiResponse, A extends Account<R>>
    = ApiAction<R, A> Function(Map<String, dynamic> props, dynamic data);

class ApiActionTypeAdapter<R extends ApiResponse, A extends Account<R>>
    extends TypeAdapter<ApiAction<R, A>> {
  final Map<String, ApiActionDeserializer<R, A>> deserializers;
  @override
  final int typeId;

  ApiActionTypeAdapter(
    this.deserializers, {
    this.typeId = 0,
  });

  @override
  ApiAction<R, A> read(BinaryReader reader) {
    int n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    final name = fields[_fieldName];
    final deserializer = deserializers[name];
    final props = (fields[_fieldProps] as Map).cast<String, dynamic>();
    final data = fields[_fieldBinaryData];
    if (deserializer == null) {
      return UnknownAction<R, A>(
        name: name,
        props: props,
        binaryData: data,
      );
    }
    return deserializer.call(props, data);
  }

  @override
  void write(BinaryWriter writer, ApiAction<R, A> obj) {
    writer.writeByte(3);
    writer.writeByte(_fieldName);
    writer.write(obj.name);
    writer.writeByte(_fieldProps);
    writer.write(obj.toMap());
    writer.writeByte(_fieldBinaryData);
    writer.write(obj.binaryData);
  }
}
