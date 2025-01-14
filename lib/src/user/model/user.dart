import 'package:json_annotation/json_annotation.dart';
import 'package:kakao_flutter_sdk/src/user/model/account.dart';

part 'user.g.dart';

/// Response from [UserApi.me()].
@JsonSerializable(
    fieldRename: FieldRename.snake, explicitToJson: true, includeIfNull: false)
class User {
  /// <nodoc>
  User(this.hasSignedUp);

  /// app user id
  int id;

  /// whether this user is connected to the service or not.
  bool hasSignedUp;

  /// custom properties this user has.
  ///
  Map<String, String> properties;
  Account kakaoAccount;

  /// <nodoc>
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// <nodoc>
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() => toJson().toString();
}
