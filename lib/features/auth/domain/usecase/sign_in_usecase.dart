import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/auth/domain/entities/user_entity.dart';
import 'package:melodix/features/auth/domain/repo/auth_repo.dart';

class SignInUsecase implements UseCase<UserEntity, SignInParams> {
  final AuthRepo authRepo;  
  SignInUsecase(this.authRepo);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) {
    return authRepo.signIn(params: params);
  }
  

}

class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}