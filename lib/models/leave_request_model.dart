import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequestModel {
  final String leaveId;
  final String userId;
  final String name;
  final String leaveType;
  final Timestamp startDate;
  final Timestamp endDate;
  final String dayType; // e.g., 'Half Day', 'Full Day'
  final String reason;
  final String status;
  final Timestamp dateSubmitted;
  final String? approvedBy; // Made nullable to handle missing field

  LeaveRequestModel({
    required this.leaveId,
    required this.userId,
    required this.name,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.dayType,
    required this.reason,
    required this.status,
    required this.dateSubmitted,
    this.approvedBy,
  });

  // Convert Firestore document to LeaveRequestModel
  factory LeaveRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveRequestModel(
      leaveId: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      leaveType: data['leaveType'] ?? '',
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      dayType: data['dayType'] ?? 'Full Day',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'Pending',
      dateSubmitted: data['dateSubmitted'] ?? Timestamp.now(),
      approvedBy: data.containsKey('approvedBy') ? data['approvedBy'] : null,
    );
  }

  // Convert LeaveRequestModel to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'dayType': dayType,
      'reason': reason,
      'status': status,
      'dateSubmitted': dateSubmitted,
      'approvedBy': approvedBy,
    };
  }
}
