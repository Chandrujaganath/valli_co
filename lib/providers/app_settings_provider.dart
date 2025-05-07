import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSettingsProvider extends ChangeNotifier {
  // Make the field final and provide an actual use for it
  final bool _useModernUI = true;

  // Add a getter method to expose the field
  bool get useModernUI => _useModernUI;

  // Theme-related settings
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;

    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

    notifyListeners();
  }

  // Load the saved preferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    // We could similarly load other settings like the UI mode
    // if we made it configurable in the future

    notifyListeners();
  }

  bool _isLoading = false;

  // Getters
  bool get isLoading => _isLoading;

  // Constructor - load settings
  AppSettingsProvider() {
    _loadSettings();
  }

  // Load settings from SharedPreferences and Firestore
  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try to load from SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();

      // Set useModernUI to true in SharedPreferences
      await prefs.setBool('use_modern_ui', true);

      // Then try to sync with Firestore if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // Set useModernUI to true in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'useModernUI': true,
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle function no longer needed since Modern UI is always enabled
  // Keeping a simplified version for compatibility
  Future<void> toggleModernUI(bool value) async {
    // No change needed as it's always true
    notifyListeners();
  }
}
