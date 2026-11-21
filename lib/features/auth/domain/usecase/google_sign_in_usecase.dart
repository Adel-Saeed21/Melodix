import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/auth/domain/entities/user_entity.dart';
import 'package:melodix/features/auth/domain/repo/auth_repo.dart';

class GoogleSignInUseCase implements UseCase<UserEntity, NoParams> {
  GoogleSignInUseCase(this.authRepo);
  final AuthRepo authRepo;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return authRepo.signInWithGoogle();
  }
}
