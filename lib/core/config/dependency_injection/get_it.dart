import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:melodix/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:melodix/features/auth/data/repo_implementation/auth_repo_impl.dart';
import 'package:melodix/features/auth/domain/repo/auth_repo.dart';
import 'package:melodix/features/auth/domain/usecase/google_sign_in_usecase.dart';
import 'package:melodix/features/auth/domain/usecase/register_usecase.dart';
import 'package:melodix/features/auth/domain/usecase/sign_in_usecase.dart';
import 'package:melodix/features/auth/presentation/logic/auth_bloc.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  _setupAuth();
}

void _setupAuth() {
  // External
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  // Data source
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () =>
        AuthRemoteDataSourceImpl(getIt<FirebaseAuth>(), getIt<GoogleSignIn>()),
  );

  // Repo
  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(getIt<AuthRemoteDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<AuthRepo>()),
  );
  getIt.registerLazySingleton<SignInUsecase>(
    () => SignInUsecase(getIt<AuthRepo>()),
  );
  getIt.registerLazySingleton<GoogleSignInUseCase>(
    () => GoogleSignInUseCase(getIt<AuthRepo>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      registerUseCase: getIt<RegisterUseCase>(),
      signInUsecase: getIt<SignInUsecase>(),
      googleSignInUseCase: getIt<GoogleSignInUseCase>(),
    ),
  );
}
