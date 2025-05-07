// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/attendance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClockInOutButton extends StatefulWidget {
  const ClockInOutButton({Key? key}) : super(key: key);

  @override
  _ClockInOutButtonState createState() => _ClockInOutButtonState();
}

class _ClockInOutButtonState extends State<ClockInOutButton> {
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _checkClockInStatus();
  }

  Future<void> _checkClockInStatus() async {
    // Check if user is already clocked in (optional)
  }

  Future<void> _toggleClockInOut() async {
    Position? position = await _determinePosition();
    if (position == null) {
      _showSnackBar('Location permissions are denied.');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (!_isClockedIn) {
      // Clock In
      String? error = await _attendanceService.clockIn(DateTime.now(), position, userId);
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
      String? error = await _attendanceService.clockOut(DateTime.now(), position, userId);
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
    return await Geolocator.getCurrentPosition();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final duration = DateTime.now().difference(_clockInTime!);
      setState(() {
        _elapsedTime = _formatDuration(duration);
      });
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
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isClockedIn
                  ? [Colors.red.shade300, Colors.red.shade600]
                  : [Colors.green.shade300, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 24.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status and Timer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isClockedIn ? 'Clocked In' : 'Clocked Out',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isClockedIn
                        ? 'Working Time: $_elapsedTime'
                        : 'Tap to Clock In',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // Clock In/Out Button
              ElevatedButton(
                onPressed: _toggleClockInOut,
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 24.0,
                  ),
                ),
                child: Text(
                  _isClockedIn ? 'Clock Out' : 'Clock In',
                  style: TextStyle(
                    color: _isClockedIn
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
