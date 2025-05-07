import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String userId;
  String name;
  String email;
  String role;
  bool isActive;
  String mobileNumber;
  String branchId;
  String address;
  Timestamp dob;
  Timestamp joiningDate;
  String profilePhotoUrl;

  // Add this line
  bool isOnline; // or bool? if you prefer

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.mobileNumber,
    required this.branchId,
    required this.address,
    required this.dob,
    required this.joiningDate,
    required this.profilePhotoUrl,
    // Add optional default:
    this.isOnline = false,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      isActive: data['isActive'] ?? true,
      mobileNumber: data['mobileNumber'] ?? '',
      branchId: data['branchId'] ?? '',
      address: data['address'] ?? '',
      dob: data['dob'] ?? Timestamp.now(),
      joiningDate: data['joiningDate'] ?? Timestamp.now(),
      profilePhotoUrl: data['profilePhotoUrl'] ?? '',

      // Safely handle isOnline, defaulting to false if missing:
      isOnline: data['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'mobileNumber': mobileNumber,
      'branchId': branchId,
      'address': address,
      'dob': dob,
      'joiningDate': joiningDate,
      'profilePhotoUrl': profilePhotoUrl,

      // Also write isOnline
      'isOnline': isOnline,
    };
  }
}
