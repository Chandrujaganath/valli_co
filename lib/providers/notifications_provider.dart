// lib/providers/notifications_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsProvider extends ChangeNotifier {
  bool _enablePush = true;
  bool _soundAndVibration = true;
  bool _inAppAlerts = true;

  // Keys for shared preferences
  static const String _keyEnablePush = 'enable_push_notifications';
  static const String _keySoundVibration = 'notification_sound_vibration';
  static const String _keyInAppAlerts = 'notification_in_app_alerts';

  NotificationsProvider() {
    _loadSettings();
  }

  bool get enablePush => _enablePush;
  bool get soundAndVibration => _soundAndVibration;
  bool get inAppAlerts => _inAppAlerts;

  set enablePush(bool value) {
    if (_enablePush != value) {
      _enablePush = value;
      _saveSettings();
      notifyListeners();
    }
  }

  set soundAndVibration(bool value) {
    if (_soundAndVibration != value) {
      _soundAndVibration = value;
      _saveSettings();
      notifyListeners();
    }
  }

  set inAppAlerts(bool value) {
    if (_inAppAlerts != value) {
      _inAppAlerts = value;
      _saveSettings();
      notifyListeners();
    }
  }

  // Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _enablePush = prefs.getBool(_keyEnablePush) ?? true;
      _soundAndVibration = prefs.getBool(_keySoundVibration) ?? true;
      _inAppAlerts = prefs.getBool(_keyInAppAlerts) ?? true;

      notifyListeners();
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_keyEnablePush, _enablePush);
      await prefs.setBool(_keySoundVibration, _soundAndVibration);
      await prefs.setBool(_keyInAppAlerts, _inAppAlerts);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }
}
