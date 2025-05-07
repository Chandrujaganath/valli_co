// lib/services/attendance_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/attendance_model.dart';
import '../models/geo_fence_model.dart';
import '../services/leave_management_service.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Clock in method with geo-fencing
  Future<String?> clockIn(
      DateTime clockInTime, Position position, String userId) async {
    try {
      bool withinGeoFence = await isWithinGeoFence(position);
      if (!withinGeoFence) {
        return 'You are not within the allowed location to clock in.';
      }
      final userDoc = await _db.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';
      final branchId = userDoc.data()?['branchId'] as String?;
      if (branchId == null || branchId.isEmpty) {
        return 'User branch not set.';
      }
      await _db.collection('attendanceRecords').add({
        'clockIn': Timestamp.fromDate(clockInTime),
        'userId': userId,
        'name': userName,
        'status': 'Clocked In',
        'clockOut': null,
        'clockInLocation': GeoPoint(position.latitude, position.longitude),
        'branchId': branchId,
      });
      return null;
    } catch (e) {
      print("Error clocking in: $e");
      return 'Error clocking in: $e';
    }
  }

  // Clock out method with geo-fencing
  Future<String?> clockOut(
      DateTime clockOutTime, Position position, String userId) async {
    try {
      bool withinGeoFence = await isWithinGeoFence(position);
      if (!withinGeoFence) {
        return 'You are not within the allowed location to clock out.';
      }
      final query = await _db
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Clocked In')
          .orderBy('clockIn', descending: true)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await _db.collection('attendanceRecords').doc(docId).update({
          'clockOut': Timestamp.fromDate(clockOutTime),
          'status': 'Clocked Out',
          'clockOutLocation': GeoPoint(position.latitude, position.longitude),
        });
        return null;
      } else {
        return 'No clock-in record found.';
      }
    } catch (e) {
      print("Error clocking out: $e");
      return 'Error clocking out: $e';
    }
  }

  // Check if position is within geo-fenced area
  Future<bool> isWithinGeoFence(Position position) async {
    try {
      final geoFences = await _db.collection('geoFences').get();
      for (var doc in geoFences.docs) {
        final data = doc.data();
        final geoPoint = data['location'] as GeoPoint;
        final radius = data['radius'] as double;
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          geoPoint.latitude,
          geoPoint.longitude,
        );
        if (distance <= radius) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error checking geo-fence: $e");
      return false;
    }
  }

  // Fetch all attendance records
  Future<List<AttendanceModel>> getAttendanceRecords() async {
    try {
      QuerySnapshot snapshot = await _db.collection('attendanceRecords').get();
      return snapshot.docs
          .map((doc) => AttendanceModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error fetching attendance records: $e");
      return [];
    }
  }

  // Fetch attendance records for a specific user
  Future<List<AttendanceModel>> getUserAttendanceRecords(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .orderBy('clockIn', descending: true)
          .get();
      print(
          'AttendanceService: Fetched ${snapshot.docs.length} records for userId: $userId');
      return snapshot.docs
          .map((doc) => AttendanceModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error fetching user attendance records: $e");
      return [];
    }
  }

  // Add geo-fence location (Admin)
  Future<void> addGeoFence(
      GeoPoint location, double radius, String name) async {
    try {
      await _db.collection('geoFences').add({
        'location': location,
        'radius': radius,
        'name': name,
      });
    } catch (e) {
      print("Error adding geo-fence: $e");
    }
  }

  // Fetch all geo-fence locations
  Future<List<GeoFenceModel>> getGeoFences() async {
    try {
      QuerySnapshot snapshot = await _db.collection('geoFences').get();
      return snapshot.docs
          .map((doc) => GeoFenceModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print("Error fetching geo-fences: $e");
      return [];
    }
  }

  // Delete geo-fence location (Admin)
  Future<void> deleteGeoFence(String geoFenceId) async {
    try {
      await _db.collection('geoFences').doc(geoFenceId).delete();
    } catch (e) {
      print("Error deleting geo-fence: $e");
    }
  }

  // Check if user is currently clocked in
  Future<bool> isUserClockedIn(String userId) async {
    try {
      final query = await _db
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Clocked In')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking clock-in status: $e');
      return false;
    }
  }

  // Get the current clock-in status and time for a user
  Future<AttendanceModel?> getClockInStatus(String userId) async {
    try {
      final query = await _db
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Clocked In')
          .orderBy('clockIn', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return AttendanceModel.fromDocument(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting clock-in status: $e');
      return null;
    }
  }

  /// Determine the attendance status for a given user and date.
  Future<String> getDailyAttendanceStatus(String userId, DateTime date) async {
    final leaveService = LeaveManagementService();
    bool isOnLeave =
        await leaveService.isUserOnApprovedLeaveForDate(userId, date);
    if (isOnLeave) {
      return 'On Leave';
    }
    final startOfDay =
        Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0));
    final endOfDay = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, 23, 59, 59));
    final recordsQuery = await _db
        .collection('attendanceRecords')
        .where('userId', isEqualTo: userId)
        .where('clockIn', isGreaterThanOrEqualTo: startOfDay)
        .where('clockIn', isLessThanOrEqualTo: endOfDay)
        .orderBy('clockIn', descending: false)
        .get();
    if (recordsQuery.docs.isEmpty) {
      return 'Absent';
    }
    DateTime? earliestClockIn;
    DateTime? latestClockOut;
    for (var doc in recordsQuery.docs) {
      final data = doc.data();
      DateTime ci = (data['clockIn'] as Timestamp).toDate();
      earliestClockIn ??= ci;
      if (ci.isBefore(earliestClockIn)) {
        earliestClockIn = ci;
      }
      if (data['clockOut'] != null) {
        DateTime co = (data['clockOut'] as Timestamp).toDate();
        if (latestClockOut == null || co.isAfter(latestClockOut)) {
          latestClockOut = co;
        }
      }
    }
    final earliestCI = earliestClockIn!;
    if (earliestCI.hour > 10) {
      return 'Late';
    } else {
      if (latestClockOut != null &&
          latestClockOut.hour >= 20 &&
          earliestCI.hour <= 9) {
        return 'Present';
      } else {
        return 'Late';
      }
    }
  }

  /// Get attendance status for each day of a given month for a user.
  Future<Map<DateTime, String>> getAttendanceForMonth(
      String userId, int year, int month) async {
    Map<DateTime, String> monthData = {};
    DateTime lastDay = DateTime(year, month + 1, 0);
    for (int i = 0; i < lastDay.day; i++) {
      DateTime day = DateTime(year, month, i + 1);
      final status = await getDailyAttendanceStatus(userId, day);
      monthData[day] = status;
    }
    return monthData;
  }
}
