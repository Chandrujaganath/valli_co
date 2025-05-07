// lib/providers/announcement_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementProvider with ChangeNotifier {
  List<Announcement> _announcements = [];
  bool _isLoading = false;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;

  AnnouncementProvider() {
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('pinned', descending: true)
        .orderBy('timestamp', descending: true)
        .get();

    _announcements = snapshot.docs
        .map((doc) => Announcement.fromMap(doc.data(), doc.id))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAnnouncement(String title, String message, bool pinned, List<String> targetRoles) async {
    final announcement = Announcement(
      id: '',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isActive: true,
      pinned: pinned,
      targetRoles: targetRoles.isEmpty ? ['all'] : targetRoles,
    );

    final docRef = await FirebaseFirestore.instance
        .collection('announcements')
        .add(announcement.toMap());

    final newAnnouncement = announcement.copyWith(id: docRef.id);
    _announcements.insert(0, newAnnouncement);
    notifyListeners();
  }

  Future<void> removeAnnouncement(String id) async {
    await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
    _announcements.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> updateAnnouncement(Announcement updated) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(updated.id)
        .update(updated.toMap());

    final index = _announcements.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _announcements[index] = updated;
      notifyListeners();
    }
  }
}

extension on Announcement {
  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isActive,
    bool? pinned,
    List<String>? targetRoles,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
      pinned: pinned ?? this.pinned,
      targetRoles: targetRoles ?? this.targetRoles,
    );
  }
}
