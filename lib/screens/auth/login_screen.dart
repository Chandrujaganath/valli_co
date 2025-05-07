// lib/screens/auth/login_screen.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, control_flow_in_finally

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts
import '../../auth/auth_service.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for email and password input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Key to identify the form and perform validation
  final _formKey = GlobalKey<FormState>();

  // Loading state to show progress indicator during authentication
  bool _isLoading = false;

  // Whether the password is currently obscured (hidden) or visible
  bool _passwordObscured = true;

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method to handle login action
  Future<void> _login() async {
    final appLocalization = AppLocalizations.of(context);

    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        // UPDATED: Pass the BuildContext to signInWithEmail so that it can create or load the user document.
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          context,
        );
      } on AuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalization?.translate(e.message) ?? 'Login failed',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalization?.translate('login_failed') ?? 'Login failed',
            ),
          ),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to build text fields with consistent styling and localization
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelKey,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    // Optional suffix icon for toggling password
    Widget? suffixIcon,
  }) {
    final appLocalization = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalization?.translate(labelKey) ?? labelKey,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color.fromARGB(255, 17, 17, 17).withOpacity(0.2),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            // Only display the suffix icon if provided
            suffixIcon: suffixIcon,
          ),
          style: const TextStyle(color: Colors.white),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return appLocalization?.translate('field_required') ??
                      'This field is required';
                }
                return null;
              },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // New gradient: sky blue at the top, darker blue in the middle, black at the bottom
          gradient: LinearGradient(
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFF0D47A1), // Darker blue
              Colors.black, // Black
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            // Space between content and bottom "Powered by" section
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Main content wrapped in Expanded + SingleChildScrollView for scrollability
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        // App Title (now showing "Valli & Co")
                        Text(
                          appLocalization?.translate('app_title') ??
                              'Valli & Co',
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Input Field
                        _buildTextField(
                          controller: _emailController,
                          labelKey: 'email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return appLocalization
                                      ?.translate('field_required') ??
                                  'This field is required';
                            }
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return appLocalization
                                      ?.translate('invalid_email') ??
                                  'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Input Field + Eye Icon to toggle visibility
                        _buildTextField(
                          controller: _passwordController,
                          labelKey: 'password',
                          obscureText: _passwordObscured,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return appLocalization
                                      ?.translate('field_required') ??
                                  'This field is required';
                            }
                            if (value.length < 6) {
                              return appLocalization
                                      ?.translate('password_length') ??
                                  'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          // Suffix icon for toggling password visibility
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordObscured = !_passwordObscured;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 34),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    appLocalization?.translate('login') ??
                                        'Login',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom "Powered by" section
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Powered by ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Image.asset(
                      'assets/images/login_bottom.png',
                      height: 40, // Smaller size for the bottom logo
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
