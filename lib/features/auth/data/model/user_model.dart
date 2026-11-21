import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodix/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
  });

  factory UserModel.fromFirebase(User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
    );
  }
}
