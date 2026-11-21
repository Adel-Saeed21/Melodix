import 'package:equatable/equatable.dart';
import 'package:melodix/features/auth/domain/entities/user_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted after a Google sign-in. Google accounts are signed in immediately,
/// so screens should go straight to home (even from the register screen).
class GoogleAuthSuccess extends AuthSuccess {
  const GoogleAuthSuccess(super.user);
}
