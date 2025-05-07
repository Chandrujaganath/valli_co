// lib/services/user_service.dart

// ignore_for_file: avoid_print, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? currentUser;
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      return doc.exists ? UserModel.fromDocument(doc) : null;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  // Fetch users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching users by role: $e");
      return [];
    }
  }
  
  Future<void> updateUserFCMToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    await _db.collection('users').doc(userId).update({'fcmToken': token});
  }

  Future<List<UserModel>> getUsers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  Future<void> addUser(UserModel user, String password) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      print("Current user UID: ${currentUser?.uid}");
      print("Is user authenticated: ${currentUser != null}");

      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Ensure Firebase Functions instance is initialized
      final functions = FirebaseFunctions.instance;

      // If you're using a custom region, specify it:
      // final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      final callable = functions.httpsCallable('createUser');
      final result = await callable.call({
        'email': user.email,
        'password': password,
        'name': user.name,
        'role': user.role,
        'isActive': user.isActive,
        'mobileNumber': user.mobileNumber,
        'branchId': user.branchId,
        'address': user.address,
        'dob': user.dob.toDate().toIso8601String(),
        'joiningDate': user.joiningDate.toDate().toIso8601String(),
        'profilePhotoUrl': user.profilePhotoUrl,
      });

      if (result.data['success'] != true) {
        throw Exception('Failed to create user');
      }
    } catch (e) {
      print("Error adding user: $e");
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.userId).set(user.toJson());
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();

      // Deleting users from Firebase Authentication requires the Admin SDK.
      // Alternatively, you can disable the user or mark them as inactive.
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  // Stream for real-time user data (optional)
  Stream<DocumentSnapshot> getUserStreamById(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }
  
  Future<List<UserModel>> getAllUsers() async {
  try {
    QuerySnapshot snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  } catch (e) {
    print("Error fetching users: $e");
    return [];
  }
}
// New method to fetch users by multiple roles
  Future<List<UserModel>> getUsersByRoles(List<String> roles) async {
    try {
      // Firestore allows a maximum of 10 values in a whereIn query
      if (roles.length > 10) {
        throw Exception('Cannot query more than 10 roles at once.');
      }

      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('role', whereIn: roles)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching users by roles: $e");
      return [];
    }
  }

  // Mark user as online
Future<void> setUserOnline(String userId) async {
  await _db.collection('users').doc(userId).update({
    'isOnline': true,
    'lastSeen': FieldValue.serverTimestamp(),
  });
}

// Mark user as offline
Future<void> setUserOffline(String userId) async {
  await _db.collection('users').doc(userId).update({
    'isOnline': false,
    'lastSeen': FieldValue.serverTimestamp(),
  });
}

}
