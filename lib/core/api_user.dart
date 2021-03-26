typedef ApiUserParser<U extends ApiUser> = U Function(Map<String, dynamic>?);

mixin ApiUser {
  bool reloadFullData(ApiUser? previous);

  Map<String, dynamic> toMap();
}
