// lib/screens/intro/intro_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/auth/auth_service.dart';
import 'package:z_emp/screens/auth/login_screen.dart';
import 'package:z_emp/widgets/main_scaffold.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create a simple fade-in animation.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    _animationController.forward();

    // After 4 seconds, navigate to the appropriate page.
    Timer(const Duration(seconds: 4), _navigateNext);
  }

  void _navigateNext() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a simple background color or gradient if you prefer.
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder animated logo. Replace FlutterLogo with your own animated widget later.
              Image.asset(
  'assets/images/logo.png',
  width: 120,
  height: 120,
),
              const SizedBox(height: 20),
              const Text(
                "Valli & Co",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
