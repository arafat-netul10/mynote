
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final String? _serverClientId;
  bool _isInitialized = false;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    this._serverClientId,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  AppUserModel? _mapUser(User? user) {
    if (user == null) return null;

    return AppUserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  @override
  Stream<AppUserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return _mapUser(credential.user)!;
  }

  @override
  Future<AppUserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(displayName.trim());
    await credential.user!.reload();

    return _mapUser(_firebaseAuth.currentUser)!;
  }

  @override
  Future<AppUserModel> signInWithGoogle({String? serverClientId}) async {
    final effectiveServerClientId = serverClientId ?? _serverClientId;

    if (!_isInitialized) {
      try {
        await _googleSignIn.initialize(
          serverClientId: effectiveServerClientId,
        );
        _isInitialized = true;
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
            (e.description != null &&
                e.description!.contains('serverClientId'))) {
          throw Exception(
            'Google Sign-In configuration error: serverClientId must be provided on Android. '
            'Ensure Google authentication is enabled in Firebase Console and google-services.json includes the Web Client ID, '
            'or pass serverClientId to FirebaseAuthRepository.',
          );
        }
        rethrow;
      }
    }

    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Failed to obtain Google ID token. Ensure serverClientId / Web Client ID is configured correctly.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return _mapUser(userCredential.user)!;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Sign-in cancelled by user.');
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          (e.description != null &&
              e.description!.contains('serverClientId'))) {
        throw Exception(
          'Google Sign-In configuration error: serverClientId must be provided on Android. '
          'Ensure Google authentication is enabled in Firebase Console and google-services.json includes the Web Client ID, '
          'or pass serverClientId to FirebaseAuthRepository.',
        );
      }
      throw Exception(
          'Google Sign-In failed: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw Exception('Firebase authentication failed: ${e.message ?? e.code}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    try {
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore Google sign out errors if user was not signed in with Google
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
}
