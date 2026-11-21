import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/auth/domain/entities/user_entity.dart';
import 'package:melodix/features/auth/domain/usecase/sign_in_usecase.dart';

abstract class AuthRepo {
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signIn({required SignInParams params});

  Future<Either<Failure, UserEntity>> signInWithGoogle();
}
