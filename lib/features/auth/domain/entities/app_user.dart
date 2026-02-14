import 'package:equatable/equatable.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isVerified;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [uid, name, email, role, isVerified];
}
