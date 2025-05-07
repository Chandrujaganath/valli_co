// lib/services/follow_up_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow_up_model.dart';

class FollowUpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  // Fetch follow-ups by enquiry ID (for subcollection structure)
  Future<List<FollowUpModel>> getFollowUpsFromSubcollection(String enquiryId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('enquiries')
          .doc(enquiryId)
          .collection('followUps')
          .orderBy('callDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => FollowUpModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching follow-ups: $e");
      return [];
    }
  }

  // Fetch follow-ups by enquiry ID from the "followUps" collection
Future<List<FollowUpModel>> getFollowUpsByEnquiry(String enquiryId) async {
  try {
    QuerySnapshot snapshot = await _db
        .collection('followUps')
        .where('enquiryId', isEqualTo: enquiryId)
        .orderBy('callDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => FollowUpModel.fromDocument(doc)).toList();
  } catch (e) {
    print("Error fetching follow-ups: $e");
    return [];
  }
}
  // Add a follow-up entry
  Future<void> addFollowUp(FollowUpModel followUp) async {
    try {
      await _db.collection('followUps').add(followUp.toJson());
    } catch (e) {
      print("Error adding follow-up: $e");
    }
  }
}
