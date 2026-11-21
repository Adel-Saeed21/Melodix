import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:melodix/core/service/secure_storage_service.dart';
import 'package:melodix/features/auth/data/model/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signInWithGoogle();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth, this._googleSignIn);
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'User creation succeeded but no user was returned.',
      );
    }

    await user.updateDisplayName(name);
    await user.reload();

    return UserModel.fromFirebase(_auth.currentUser!);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Sign-in succeeded but no user was returned.',
      );
    }
    await SecureStorageService.saveToken(user.refreshToken!);
    return UserModel.fromFirebase(_auth.currentUser!);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Google sign-in succeeded but no user was returned.',
      );
    }

    await SecureStorageService.saveToken(user.refreshToken!);
    return UserModel.fromFirebase(user);
  }
}
