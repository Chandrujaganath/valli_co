// lib/services/organisation_service.dart

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';

class OrganisationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all branches
  Future<List<BranchModel>> getBranches() async {
    try {
      QuerySnapshot snapshot = await _db.collection('branches').get();
      return snapshot.docs.map((doc) => BranchModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching branches: $e");
      return [];
    }
  }

  // Add a new branch
  Future<void> addBranch(BranchModel branch) async {
    try {
      await _db.collection('branches').add(branch.toJson());
    } catch (e) {
      print("Error adding branch: $e");
    }
  }

  // Update an existing branch
  Future<void> updateBranch(String branchId, Map<String, dynamic> data) async {
    try {
      await _db.collection('branches').doc(branchId).update(data);
    } catch (e) {
      print("Error updating branch: $e");
    }
  }

  // Delete a branch
  Future<void> deleteBranch(String branchId) async {
    try {
      await _db.collection('branches').doc(branchId).delete();
    } catch (e) {
      print("Error deleting branch: $e");
    }
  }

  // Fetch a single branch by ID
  Future<BranchModel?> getBranchById(String branchId) async {
    try {
      final doc = await _db.collection('branches').doc(branchId).get();
      if (doc.exists) {
        return BranchModel.fromDocument(doc);
      } else {
        print("Branch with ID $branchId does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching branch by ID: $e");
      return null;
    }
  }
}
