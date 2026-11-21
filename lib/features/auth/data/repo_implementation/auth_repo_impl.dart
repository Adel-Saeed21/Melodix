import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:melodix/features/auth/domain/entities/user_entity.dart';
import 'package:melodix/features/auth/domain/repo/auth_repo.dart';
import 'package:melodix/features/auth/domain/usecase/sign_in_usecase.dart';

class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.register(
        name: name,
        email: email,
        password: password,
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure('Something went wrong, try again'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required SignInParams params,
  }) async {
    try {
      final user = await _remote.signIn(
        email: params.email,
        password: params.password,
      );
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure('Something went wrong, try again'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await _remote.signInWithGoogle();
      return Right(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Left(ServerFailure('Google sign-in was cancelled'));
      }
      return const Left(ServerFailure('Google sign-in failed, try again'));
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapAuthError(e.code)));
    } catch (_) {
      return const Left(ServerFailure('Something went wrong, try again'));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'weak-password':
        return 'The password is too weak';
      case 'operation-not-allowed':
        return 'Email/password sign up is not enabled';
      case 'account-exists-with-different-credential':
        return 'This email is already registered with a password';
      case 'network-request-failed':
        return 'Check your internet connection';
      default:
        return 'Authentication failed, try again';
    }
  }
}
