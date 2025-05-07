// lib/models/branch_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String branchId;
  final String name;
  final String address;
  final int clockInMinutes; // e.g., 540 for 9 AM
  final int bufferMinutes; // e.g., 30 for 30 mins

  BranchModel({
    required this.branchId,
    required this.name,
    required this.address,
    required this.clockInMinutes,
    required this.bufferMinutes,
  });

  // Convert Firestore document to BranchModel
  factory BranchModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BranchModel(
      branchId: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      clockInMinutes: data['clockInMinutes'] ?? 540, // Default 9 AM
      bufferMinutes: data['bufferMinutes'] ?? 30, // Default 30 mins
    );
  }

  // Convert BranchModel to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'clockInMinutes': clockInMinutes,
      'bufferMinutes': bufferMinutes,
    };
  }
}
