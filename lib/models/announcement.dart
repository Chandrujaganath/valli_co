// lib/models/announcement.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isActive;
  final bool pinned;
  final List<String> targetRoles;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isActive,
    required this.pinned,
    required this.targetRoles,
  });

  factory Announcement.fromMap(Map<String, dynamic> map, String docId) {
    return Announcement(
      id: docId,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      pinned: map['pinned'] ?? false,
      targetRoles: List<String>.from(map['targetRoles'] ?? ['all']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'isActive': isActive,
      'pinned': pinned,
      'targetRoles': targetRoles,
    };
  }
}
