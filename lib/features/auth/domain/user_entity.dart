import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final bool isSitter;
  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.isSitter,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl, isSitter, isVerified];
}
