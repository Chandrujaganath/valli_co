// lib/auth/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/logger.dart';

// Define AuthException
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Public getter for current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // SIGN-IN WITH EMAIL + LOAD USER
  Future<void> signInWithEmail(
      String email, String password, BuildContext context) async {
    try {
      // Log instead of print
      AppLogger.log('Attempting sign in with email: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Log instead of print
        AppLogger.log(
            'Successfully signed in user: ${userCredential.user!.uid}');

        // Check if the BuildContext is still valid
        if (!context.mounted) return;

        // Load the user's data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadCurrentUser(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      // Use the exception properly
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'auth_error_user_not_found';
          break;
        case 'wrong-password':
          errorMessage = 'auth_error_wrong_password';
          break;
        case 'invalid-email':
          errorMessage = 'auth_error_invalid_email';
          break;
        default:
          errorMessage = 'auth_error_unknown';
      }
      throw AuthException(errorMessage);
    } catch (e) {
      // Log and rethrow
      AppLogger.log('Error during sign in: $e', level: 'error');
      throw AuthException('auth_error_unknown');
    }
  }

  // Sign out
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      // Check if the BuildContext is still valid
      if (!context.mounted) return;

      // Clear user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();
    } catch (e) {
      // Log instead of print
      AppLogger.log('Error signing out: $e', level: 'error');
      throw AuthException('auth_error_sign_out');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
