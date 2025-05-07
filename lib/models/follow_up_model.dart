// lib/models/follow_up_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpModel {
  final String followUpId;
  final String enquiryId;
  final Timestamp callDate;
  final String callResponse;
  final bool isPositive;

  FollowUpModel({
    required this.followUpId,
    required this.enquiryId,
    required this.callDate,
    required this.callResponse,
    required this.isPositive,
  });

  // Factory method to create a FollowUpModel from a Firestore document
  factory FollowUpModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowUpModel(
      followUpId: doc.id,
      enquiryId: data['enquiryId'] ?? '',
      callDate: data['callDate'] ?? Timestamp.now(),
      callResponse: data['callResponse'] ?? '',
      isPositive: data['isPositive'] ?? true,
    );
  }

  // Method to convert FollowUpModel to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
      'callDate': callDate,
      'callResponse': callResponse,
      'isPositive': isPositive,
    };
  }
}
