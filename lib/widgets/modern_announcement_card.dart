import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement.dart';

class ModernAnnouncementCard extends StatefulWidget {
  final String role;

  const ModernAnnouncementCard({
    super.key,
    required this.role,
  });

  @override
  State<ModernAnnouncementCard> createState() => _ModernAnnouncementCardState();
}

class _ModernAnnouncementCardState extends State<ModernAnnouncementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate());
    }
    if (timestamp is DateTime) {
      return DateFormat('MMM d, yyyy • h:mm a').format(timestamp);
    }
    return 'Date unavailable';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnnouncementProvider>(context);
    final announcements = provider.announcements;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;

    // Filter announcements by role
    final roleAnnouncements = announcements.where((a) {
      return a.targetRoles.contains('all') ||
          a.targetRoles.contains(widget.role);
    }).toList();

    if (roleAnnouncements.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20, vertical: isMobile ? 8 : 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1D2B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              Container(
                width: isMobile ? 40 : 50,
                height: isMobile ? 40 : 50,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 15),
                ),
                child: Icon(
                  Icons.announcement,
                  color: Colors.orangeAccent,
                  size: isMobile ? 24 : 30,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Text(
                  'No new announcements at this time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20, vertical: isMobile ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF5F6D),
                  Color(0xFFFFC371),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5F6D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: isMobile ? 40 : 50,
                        height: isMobile ? 40 : 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(isMobile ? 12 : 15),
                        ),
                        child: Icon(
                          Icons.announcement,
                          color: Colors.white,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Announcements',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 14 : null,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 6 : 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(
                                        isMobile ? 10 : 12),
                                  ),
                                  child: Text(
                                    '${roleAnnouncements.length}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              roleAnnouncements.first.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 12 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Expandable content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              height: isMobile ? 150 : 180, // Adjusted height for mobile
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: roleAnnouncements.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final announcement = roleAnnouncements[index];
                        return _buildAnnouncementItem(announcement);
                      },
                    ),
                  ),
                  if (roleAnnouncements.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          roleAnnouncements.length,
                          (index) => Container(
                            width: isMobile ? 6 : 8,
                            height: isMobile ? 6 : 8,
                            margin: EdgeInsets.symmetric(
                                horizontal: isMobile ? 3 : 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentIndex == index
                                  ? const Color(0xFFFF5F6D)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(Announcement announcement) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
      decoration: BoxDecoration(
        color: announcement.pinned
            ? const Color(0xFFFF5F6D).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.pinned)
                Icon(
                  Icons.push_pin,
                  size: isMobile ? 14 : 16,
                  color: Color(0xFFFF5F6D),
                ),
              if (announcement.pinned) SizedBox(width: isMobile ? 2 : 4),
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: announcement.pinned
                        ? const Color(0xFFFF5F6D)
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              announcement.message,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            _formatTimestamp(announcement.timestamp),
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
