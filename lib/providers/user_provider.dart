// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final UserService _userService = UserService();

  UserModel? get user => _user;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load the current user from Firestore using userId.
  Future<void> loadCurrentUser(String userId) async {
  try {
    final fetchedUser = await _userService.getUserById(userId);
    if (fetchedUser != null) {
      _user = fetchedUser;
      print("Loaded user: ${_user!.name}, Role: ${_user!.role}");
    } else {
      print("User document not found for UID: $userId");
    }
  } catch (e) {
    print("Error loading user: $e");
    rethrow;
  } finally {
    notifyListeners();
  }
}

  /// Manually set user
  void setUser(UserModel user) {
    _user = user;
    print("User set: ${user.name}, Role: ${user.role}");
    notifyListeners();
  }

  /// Clear user
  void clearUser() {
    _user = null;
    print("User cleared.");
    notifyListeners();
  }
}
