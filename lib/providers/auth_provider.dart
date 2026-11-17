
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AppUserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<AppUserModel?>? _authSubscription;

  AuthProvider({
    required this._authRepository,
  }) {
    _authSubscription = _authRepository.authStateChanges.listen(
          (user) {
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  AppUserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _execute(() => _authRepository.signInWithEmail(
      email: email,
      password: password,
    ));
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _execute(() => _authRepository.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    ));
  }

  Future<void> signInWithGoogle({String? serverClientId}) async {
    await _execute(() => _authRepository.signInWithGoogle(serverClientId: serverClientId));
  }

  Future<void> signOut() async {
    await _execute(() => _authRepository.signOut());
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _execute(
          () => _authRepository.sendPasswordResetEmail(email: email),
    );
  }

  Future<void> _execute(Future<dynamic> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
