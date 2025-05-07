// lib/services/role_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch the user's role directly as a String
  Future<String?> getCurrentUserRole(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] as String?;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching user role: $e");
      return null;
    }
  }

  // Update the role of an existing user
  Future<void> updateRole(String userId, String newRole) async {
    await _db.collection('users').doc(userId).update({'role': newRole});
  }

  // Assign a role to a user in a separate roles collection (if needed)
  Future<void> assignRole(String userId, String role) async {
    await _db.collection('roles').doc(userId).set({'role': role});
  }
}
