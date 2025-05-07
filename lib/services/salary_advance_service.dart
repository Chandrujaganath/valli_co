// lib/services/salary_advance_service.dart

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/salary_advance_model.dart';
import 'package:path/path.dart' as path; // For handling file paths

class SalaryAdvanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch all salary advances
  Future<List<SalaryAdvanceModel>> getSalaryAdvances() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('salaryAdvances')
          .orderBy('dateSubmitted', descending: true)
          .get();
      return snapshot.docs.map((doc) => SalaryAdvanceModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching salary advances: $e");
      return [];
    }
  }

  // Fetch salary advances for a specific user
  Future<List<SalaryAdvanceModel>> getUserSalaryAdvances(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('salaryAdvances')
          .where('userId', isEqualTo: userId)
          .orderBy('dateSubmitted', descending: true)
          .get();
      return snapshot.docs.map((doc) => SalaryAdvanceModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching user salary advances: $e");
      return [];
    }
  }

  // Add a new salary advance request with optional attachment
  Future<void> submitSalaryAdvanceRequest(SalaryAdvanceModel salaryAdvance, {PlatformFile? file}) async {
    try {
      String attachmentUrl = '';
      if (file != null) {
        // Determine if bytes are available
        if (file.bytes != null) {
          // Upload using bytes
          final storageRef = _storage.ref().child('salary_advances/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
          UploadTask uploadTask = storageRef.putData(file.bytes!);
          TaskSnapshot snapshot = await uploadTask;

          if (snapshot.state == TaskState.success) {
            attachmentUrl = await snapshot.ref.getDownloadURL();
            print("File uploaded successfully: $attachmentUrl");
          } else {
            print("File upload failed.");
            throw Exception("File upload failed");
          }
        } else if (file.path != null) {
          // Upload using file path
          File f = File(file.path!);
          String fileName = 'salary_advances/${DateTime.now().millisecondsSinceEpoch}_${path.basename(f.path)}';

          final storageRef = _storage.ref().child(fileName);
          UploadTask uploadTask = storageRef.putFile(f);
          TaskSnapshot snapshot = await uploadTask;

          if (snapshot.state == TaskState.success) {
            attachmentUrl = await snapshot.ref.getDownloadURL();
            print("File uploaded successfully: $attachmentUrl");
          } else {
            print("File upload failed.");
            throw Exception("File upload failed");
          }
        } else {
          print("No file data available for upload.");
          throw Exception("No file data available for upload");
        }
      }

      final docRef = _db.collection('salaryAdvances').doc();
      salaryAdvance.advanceId = docRef.id;
      salaryAdvance.attachmentUrl = attachmentUrl;

      await docRef.set(salaryAdvance.toJson());
      print("Salary advance request saved successfully with ID: ${docRef.id}");
    } catch (e) {
      print("Error adding salary advance: $e");
      rethrow; // Rethrow to handle in UI
    }
  }

  // Update the status of an existing salary advance
  Future<void> updateSalaryAdvanceStatus(String advanceId, String newStatus, {required String approvedBy}) async {
    try {
      Map<String, dynamic> data = {
        'status': newStatus,
        'approvedBy': approvedBy,
        'approvalDate': Timestamp.now(),
      };
      await _db.collection('salaryAdvances').doc(advanceId).update(data);
      print("Salary advance status updated to $newStatus for ID: $advanceId");
    } catch (e) {
      print("Error updating salary advance status: $e");
      rethrow; // Rethrow to handle in UI
    }
  }
}
