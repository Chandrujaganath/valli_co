// lib/utils/validators.dart
class Validators {
  static String? validateEmail(String? value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (value == null || !emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    final phoneRegex = RegExp(r'^\d{10}$');
    if (value == null || !phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || double.tryParse(value) == null) {
      return 'Enter a valid amount';
    }
    return null;
  }
}
