import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/auth/domain/entities/app_user.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.role,
    super.isVerified,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final roleStr = (data['role'] ?? data['userType'])?.toString();

    return UserModel(
      uid: doc.id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: UserRole.fromString(roleStr) ?? UserRole.petOwner,
      isVerified: data['isVerified'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.firestoreValue,
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCreateFirestore() {
    return {
      ...toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
