// lib/widgets/announcement_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementCard extends StatefulWidget {
  final String role; // e.g. "admin", "manager", "sales", "measurement"
  const AnnouncementCard({super.key, required this.role});

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller; // Ensure late initialization
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the controller in initState
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    // If timestamp is a Firestore Timestamp, format it.
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnnouncementProvider>(context);
    final announcements = provider.announcements;

    // Filter announcements by role
    final roleAnnouncements = announcements.where((a) {
      return a.targetRoles.contains('all') || a.targetRoles.contains(widget.role);
    }).toList();

    if (roleAnnouncements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: const [
              Icon(Icons.announcement, size: 40, color: Colors.black54),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No new announcements at this time.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              offset: Offset(0, 3),
              color: Colors.black26,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animated expand/collapse icon
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.announcement, size: 40, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Announcements',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleExpanded,
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.menu_close,
                      progress: _expandAnimation,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            // Expandable content: if expanded, show horizontal list; if not, show first announcement
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expanded
                  ? SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: roleAnnouncements.length,
                        itemBuilder: (context, index) {
                          final announcement = roleAnnouncements[index];
                          return _buildAnnouncementItem(announcement);
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: _buildAnnouncementItem(roleAnnouncements.first),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(Announcement announcement) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: announcement.pinned ? Colors.redAccent : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.pinned)
            const Text(
              '📌 Pinned',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            announcement.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: announcement.pinned ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Message wrapped in a scrollable container
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 60),
            child: SingleChildScrollView(
              child: Text(
                announcement.message,
                style: TextStyle(
                  fontSize: 14,
                  color: announcement.pinned ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posted on: ${_formatTimestamp(announcement.timestamp)}',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: announcement.pinned ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
