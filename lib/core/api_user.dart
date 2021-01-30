typedef ApiUserParser<U extends ApiUser> = U Function(Map<String, dynamic>);

mixin ApiUser {
  int get id;
  int get permissions;
  String get name;

  bool hasPermission(int permission) {
    return (permission & permissions) != 0;
  }

  Map<String, dynamic> toMap();

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ApiUser &&
        o.id == id &&
        o.permissions == permissions &&
        o.name == name;
  }
}