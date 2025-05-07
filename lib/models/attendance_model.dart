// lib/models/attendance_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String branchId;
  final Timestamp clockIn;
  final GeoPoint clockInLocation;
  final Timestamp? clockOut;
  final GeoPoint? clockOutLocation;
  final String name;
  final String status;
  final String userId;

  AttendanceModel({
    required this.branchId,
    required this.clockIn,
    required this.clockInLocation,
    this.clockOut,
    this.clockOutLocation,
    required this.name,
    required this.status,
    required this.userId,
  });

  // Convert Firestore document to AttendanceModel
  factory AttendanceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      branchId: data['branchId'] ?? '',
      clockIn: data['clockIn'] ?? Timestamp.now(),
      clockInLocation: data['clockInLocation'] ?? GeoPoint(0, 0),
      clockOut: data['clockOut'],
      clockOutLocation: data['clockOutLocation'],
      name: data['name'] ?? '',
      status: data['status'] ?? '',
      userId: data['userId'] ?? '',
    );
  }

  // Convert AttendanceModel to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'clockIn': clockIn,
      'clockInLocation': clockInLocation,
      'clockOut': clockOut,
      'clockOutLocation': clockOutLocation,
      'name': name,
      'status': status,
      'userId': userId,
    };
  }
}
