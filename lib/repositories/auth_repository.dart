



import '../models/app_user_model.dart';

abstract class AuthRepository {
  Stream<AppUserModel?> get authStateChanges;

  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUserModel> signInWithGoogle({String? serverClientId});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({
    required String email,
  });
}