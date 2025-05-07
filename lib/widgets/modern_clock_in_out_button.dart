import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/attendance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModernClockInOutButton extends StatefulWidget {
  const ModernClockInOutButton({super.key});

  @override
  State<ModernClockInOutButton> createState() => _ModernClockInOutButtonState();
}

class _ModernClockInOutButtonState extends State<ModernClockInOutButton>
    with SingleTickerProviderStateMixin {
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  final AttendanceService _attendanceService = AttendanceService();

  // For animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _checkClockInStatus();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkClockInStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final status = await _attendanceService.getClockInStatus(userId);
      if (status != null && status.clockIn != null && status.clockOut == null) {
        setState(() {
          _isClockedIn = true;
          _clockInTime = status.clockIn.toDate();
          _startTimer();
        });
      }
    }
  }

  Future<void> _toggleClockInOut() async {
    _animationController.forward().then((_) => _animationController.reverse());

    Position? position = await _determinePosition();
    if (position == null) {
      _showSnackBar('Location permissions are denied.');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (!_isClockedIn) {
      // Clock In
      String? error =
          await _attendanceService.clockIn(DateTime.now(), position, userId);
      if (error != null) {
        _showSnackBar(error);
        return;
      }
      setState(() {
        _isClockedIn = true;
        _clockInTime = DateTime.now();
        _startTimer();
      });
      _showSnackBar('Successfully clocked in.');
    } else {
      // Clock Out
      String? error =
          await _attendanceService.clockOut(DateTime.now(), position, userId);
      if (error != null) {
        _showSnackBar(error);
        return;
      }
      setState(() {
        _isClockedIn = false;
        _timer?.cancel();
        _elapsedTime = '00:00:00';
      });
      _showSnackBar('Successfully clocked out.');
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Please enable location services.');
      return null;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied.');
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showSnackBar('Location permissions are denied.');
        return null;
      }
    }

    // Get current position
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      _showSnackBar('Error getting location: $e');
      return null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_clockInTime != null) {
        final duration = DateTime.now().difference(_clockInTime!);
        setState(() {
          _elapsedTime = _formatDuration(duration);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isClockedIn
                  ? [const Color(0xFFFF5F6D), const Color(0xFFFF8E53)]
                  : [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isClockedIn
                    ? const Color(0xFFFF5F6D).withOpacity(0.3)
                    : const Color(0xFF00B4DB).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleClockInOut,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                child: Row(
                  children: [
                    // Icon with background
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _isClockedIn ? Icons.timer : Icons.login,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isClockedIn
                                ? 'Currently Working'
                                : 'Ready to Start?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isClockedIn
                                ? 'Work Time: $_elapsedTime'
                                : 'Tap to clock in for your shift',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _isClockedIn ? 'Clock Out' : 'Clock In',
                        style: TextStyle(
                          color: _isClockedIn
                              ? const Color(0xFFFF5F6D)
                              : const Color(0xFF00B4DB),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
