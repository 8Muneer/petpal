import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:petpal/features/auth/domain/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
    String? photoUrl,
    required bool isSitter,
    required bool isVerified,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
      isSitter: entity.isSitter,
      isVerified: entity.isVerified,
    );
  }

  const UserModel._();

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
      isSitter: isSitter,
      isVerified: isVerified,
    );
  }
}
