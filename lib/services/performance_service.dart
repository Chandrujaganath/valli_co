// lib/services/performance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/performance_model.dart';
import '../utils/constants.dart';

class PerformanceService {
  final CollectionReference _performanceCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.performance);

  // Fetch all performance records for the team
  Future<List<PerformanceModel>> getTeamPerformance() async {
    try {
      QuerySnapshot querySnapshot = await _performanceCollection.get();
      return querySnapshot.docs
          .map((doc) => PerformanceModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching team performance records: $e');
    }
  }

  // Fetch performance records for a specific reporting period
  Future<List<PerformanceModel>> getPerformanceByPeriod(String period) async {
    try {
      QuerySnapshot querySnapshot = await _performanceCollection
          .where('reportingPeriod', isEqualTo: period)
          .get();
      return querySnapshot.docs
          .map((doc) => PerformanceModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching performance by period: $e');
    }
  }

  // Fetch performance for a specific user
  Future<PerformanceModel?> getUserPerformance(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _performanceCollection
          .where('userId', isEqualTo: userId)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return PerformanceModel.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user performance: $e');
    }
  }

  // Add a new performance record
  Future<void> addPerformanceRecord(PerformanceModel performance) async {
    try {
      await _performanceCollection.add(performance.toMap());
    } catch (e) {
      throw Exception('Error adding performance record: $e');
    }
  }

  // Update an existing performance record
  Future<void> updatePerformanceRecord(String performanceId, Map<String, dynamic> updatedFields) async {
    try {
      await _performanceCollection
          .doc(performanceId)
          .update(updatedFields);
    } catch (e) {
      throw Exception('Error updating performance record: $e');
    }
  }
}
