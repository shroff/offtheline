part of 'actions.dart';

const _fieldName = 0;
const _fieldProps = 1;
const _fieldBinaryData = 2;

typedef ApiActionDeserializer<A extends ApiClient> = ApiAction<A> Function(
    Map<String, dynamic> props, dynamic data);

class ApiActionTypeAdapter extends TypeAdapter<ApiAction> {
  final Map<String, ApiActionDeserializer> deserializers;

  ApiActionTypeAdapter(this.deserializers);

  @override
  ApiAction<ApiClient> read(BinaryReader reader) {
    int n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    final name = fields[_fieldName];
    assert(deserializers.containsKey(name));
    final props = fields[_fieldProps] as Map;
    final data = fields[_fieldBinaryData];
    return deserializers[fields[_fieldName]!]!(
        props.cast<String, dynamic>(), data);
  }

  @override
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, ApiAction<ApiClient> action) {
    writer.writeByte(3);
    writer.writeByte(_fieldName);
    writer.write(action.name);
    writer.writeByte(_fieldProps);
    writer.write(action.toMap());
    writer.writeByte(_fieldBinaryData);
    writer.write(action.binaryData);
  }
}
