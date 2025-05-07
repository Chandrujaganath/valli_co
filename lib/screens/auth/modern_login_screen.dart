import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // For WidgetStateProperty and WidgetState
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../auth/auth_service.dart';
import '../../l10n/app_localizations.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with SingleTickerProviderStateMixin {
  // Form controllers and key
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;

  // Page controller for swipe effect
  final PageController _pageController = PageController();

  // State variables
  bool _isLoading = false;
  bool _passwordObscured = true;
  bool _rememberMe = false;
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const ShakeCurve(count: 3, offset: 5),
      ),
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideUpAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Load saved email if "remember me" was checked
    _loadSavedEmail();

    // Start initial animations
    _animationController.forward();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (savedEmail != null && rememberMe) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    final appLocalization = AppLocalizations.of(context);

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Save email if remember me is checked
      await _saveEmail();

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          context,
        );
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = appLocalization?.translate(e.message) ?? e.message;
        });
        // Shake animation for error
        _animationController.reset();
        _animationController.forward();
      } catch (e) {
        setState(() {
          _errorMessage =
              appLocalization?.translate('login_failed') ?? 'Login failed';
        });
        // Shake animation for error
        _animationController.reset();
        _animationController.forward();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Shake animation for invalid form
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _changePage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Main Content
          SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                // First page - Welcome
                _buildWelcomePage(context, size),

                // Second page - Login Form
                _buildLoginPage(appLocalization, size),
              ],
            ),
          ),

          // Bottom navigation dots
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0),
                const SizedBox(width: 8),
                _buildPageIndicator(1),
              ],
            ),
          ),

          // "Powered by zenn" footer
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: _buildPoweredBySection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageIndex) {
    return GestureDetector(
      onTap: () => _changePage(pageIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 8,
        width: _currentPage == pageIndex ? 24 : 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentPage == pageIndex
              ? Colors.white
              : Colors.white.withValues(alpha: 64),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Dynamic 3D gradient background with wave effect
          CustomPaint(
            painter: WaveBackgroundPainter(
              colorTop: const Color(0xFF0D47A1),
              colorMiddle: const Color(0xFF102A54),
              colorBottom: Colors.black,
            ),
            size: Size.infinite,
          ),

          // Particle effect overlay
          CustomPaint(
            painter: ParticlesPainter(
              particleCount: 70,
              color: Colors.white.withValues(alpha: 76),
            ),
            size: Size.infinite,
          ),

          // Optional: subtle grid pattern overlay
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/grid_pattern.png'),
                  repeat: ImageRepeat.repeat,
                  opacity: 0.2,
                  colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 51), BlendMode.srcOver),
                ),
              ),
            ),
          ),

          // Gradient overlay to enhance text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 51),
                  Colors.black.withValues(alpha: 102),
                ],
                stops: const [0.7, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context, Size size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUpAnimation.value),
          child: Opacity(
            opacity: _fadeInAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glowing effect
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 38),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 140,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // App title
                  Text(
                    AppLocalizations.of(context)?.translate('app_title') ??
                        'Valli & Co',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    AppLocalizations.of(context)?.translate('app_tagline') ??
                        'Empowering businesses through technology',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 16,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 204),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Continue button
                  ElevatedButton(
                    onPressed: () => _changePage(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withValues(alpha: 38),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.translate('continue') ??
                          'Continue',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginPage(AppLocalizations? appLocalization, Size size) {
    return SingleChildScrollView(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Back button and title bar
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => _changePage(0),
                    ),
                    Text(
                      appLocalization?.translate('login') ?? 'Login',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Login form in a glassmorphic card
                _buildGlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildLoginForm(appLocalization),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 51),
                Colors.white.withValues(alpha: 25),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 51),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppLocalizations? appLocalization) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          _buildTextField(
            controller: _emailController,
            labelText: appLocalization?.translate('email') ?? 'Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return appLocalization?.translate('field_required') ??
                    'This field is required';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return appLocalization?.translate('invalid_email') ??
                    'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Password field
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: _buildTextField(
              controller: _passwordController,
              labelText: appLocalization?.translate('password') ?? 'Password',
              icon: Icons.lock_rounded,
              obscureText: _passwordObscured,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return appLocalization?.translate('field_required') ??
                      'This field is required';
                }
                if (value.length < 6) {
                  return appLocalization?.translate('password_length') ??
                      'Password must be at least 6 characters';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _passwordObscured = !_passwordObscured;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Remember me and Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember me checkbox
              Row(
                children: [
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: _rememberMe ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Colors.transparent;
                      }),
                      checkColor: const Color(0xFF0D47A1),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocalization?.translate('remember_me') ?? 'Remember me',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Forgot password button
              TextButton(
                onPressed: () {
                  // Implement forgot password functionality
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  appLocalization?.translate('forgot_password') ??
                      'Forgot Password?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          // Error message
          if (_errorMessage != null)
            AnimatedBuilder(
              animation: _fadeInAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 30),

          // Login button
          _buildLoginButton(appLocalization),

          const SizedBox(height: 20),

          // Social login options (optional)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Divider(
                      color: Colors.white.withValues(alpha: 127),
                      thickness: 0.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  appLocalization?.translate('or_login_with') ??
                      'Or login with',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                  child: Divider(
                      color: Colors.white.withValues(alpha: 127),
                      thickness: 0.5)),
            ],
          ),

          const SizedBox(height: 20),

          // Social login buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                icon: 'assets/icons/google.png',
                onTap: () {
                  // Implement Google login
                },
              ),
              _buildSocialButton(
                icon: 'assets/icons/microsoft.png',
                onTap: () {
                  // Implement Microsoft login
                },
              ),
              _buildSocialButton(
                icon: 'assets/icons/apple.png',
                onTap: () {
                  // Implement Apple login
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 51),
            width: 1,
          ),
        ),
        child: Image.asset(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 76),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              errorStyle: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AppLocalizations? appLocalization) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2196F3), // Bright blue
            Color(0xFF0D47A1), // Deep blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 76),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                appLocalization?.translate('login') ?? 'Login',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPoweredBySection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 76),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              height: 30,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

// Wave background painter for dynamic effect
class WaveBackgroundPainter extends CustomPainter {
  final Color colorTop;
  final Color colorMiddle;
  final Color colorBottom;

  WaveBackgroundPainter({
    required this.colorTop,
    required this.colorMiddle,
    required this.colorBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate time-based animation
    final time = DateTime.now().millisecondsSinceEpoch / 3000;

    // Create Paint objects
    final Paint paintTop = Paint()
      ..color = colorTop
      ..style = PaintingStyle.fill;

    final Paint paintMiddle = Paint()
      ..color = colorMiddle
      ..style = PaintingStyle.fill;

    final Paint paintBottom = Paint()
      ..color = colorBottom
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBottom);

    // Draw middle layer with wave
    final pathMiddle = Path();
    pathMiddle.moveTo(0, size.height * 0.4);

    // Create wave effect
    for (double x = 0; x < size.width; x++) {
      final waveHeight = math.sin((x / size.width * 2 * math.pi) + time) * 20;
      pathMiddle.lineTo(x, size.height * 0.4 + waveHeight);
    }

    // Close the path
    pathMiddle.lineTo(size.width, size.height);
    pathMiddle.lineTo(0, size.height);
    pathMiddle.close();

    canvas.drawPath(pathMiddle, paintMiddle);

    // Draw top layer with different wave
    final pathTop = Path();
    pathTop.moveTo(0, size.height * 0.25);

    // Create second wave effect offset from the first
    for (double x = 0; x < size.width; x++) {
      final waveHeight =
          math.cos((x / size.width * 3 * math.pi) + time * 1.5) * 15;
      pathTop.lineTo(x, size.height * 0.25 + waveHeight);
    }

    // Close the path
    pathTop.lineTo(size.width, 0);
    pathTop.lineTo(0, 0);
    pathTop.close();

    canvas.drawPath(pathTop, paintTop);
  }

  @override
  bool shouldRepaint(WaveBackgroundPainter oldDelegate) => true;
}

// Custom curve for shake animation
class ShakeCurve extends Curve {
  final double count;
  final double offset;

  const ShakeCurve({this.count = 3, this.offset = 10});

  @override
  double transformInternal(double t) {
    return math.sin(count * 2 * math.pi * t) * offset * (1 - t);
  }
}

// Custom painter for particle effect
class ParticlesPainter extends CustomPainter {
  final int particleCount;
  final Color color;
  final List<Offset> positions = [];
  final List<double> sizes = [];
  final List<double> speeds = [];

  ParticlesPainter({
    required this.particleCount,
    required this.color,
  }) {
    final random = math.Random();
    for (int i = 0; i < particleCount; i++) {
      positions.add(Offset(
        random.nextDouble() * 500,
        random.nextDouble() * 800,
      ));
      sizes.add(random.nextDouble() * 4 + 1); // Size between 1 and 5
      speeds.add(random.nextDouble() * 1.5 + 0.5); // Speed between 0.5 and 2
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final position = positions[i];
      canvas.drawCircle(
        Offset(
          (position.dx + speeds[i]) % size.width,
          (position.dy + speeds[i]) % size.height,
        ),
        sizes[i],
        paint,
      );
      positions[i] = Offset(
        (position.dx + speeds[i]) % size.width,
        (position.dy + speeds[i]) % size.height,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}
