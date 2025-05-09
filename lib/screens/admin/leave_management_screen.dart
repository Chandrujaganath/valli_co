// lib/screens/admin/leave_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/leave_management_service.dart';
import '../../models/leave_request_model.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen>
    with SingleTickerProviderStateMixin {
  DateTime? selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String? _errorMessage;

  // UI constants
  final _primaryGradient = const LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _secondaryGradient = const LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // Color scheme
  final Color _primaryColor = const Color(0xFF6A11CB);
  final Color _accentColor = const Color(0xFF2575FC);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _warningColor = const Color(0xFFFF9800);
  final Color _textPrimaryColor = const Color(0xFF333333);
  final Color _textSecondaryColor = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Refreshes pending requests by forcing a rebuild.
  Future<void> _refreshRequests() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveManagementService =
        Provider.of<LeaveManagementService>(context, listen: false);

    // Calculate adaptive height for the pending requests section.
    final pendingSectionHeight = MediaQuery.of(context).size.height * 0.33;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Leave Management',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(gradient: _primaryGradient),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshRequests,
          color: _primaryColor,
          child: Container(
            decoration: BoxDecoration(gradient: _secondaryGradient),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildPendingRequestsSection(
                        leaveManagementService, pendingSectionHeight),
                    const SizedBox(height: 24.0),
                    _buildLeaveHistorySection(leaveManagementService),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  //  Pending Requests Section (Adaptive Height)
  // ----------------------------------------------------
  Widget _buildPendingRequestsSection(
      LeaveManagementService service, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Pending Leave Requests', Icons.watch_later_outlined),
        const SizedBox(height: 16.0),
        Container(
          height: height,
          child: FutureBuilder<List<LeaveRequestModel>>(
            future: service.getPendingLeaveRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              } else if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState('No pending leave requests found.');
              } else {
                final requests = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildPendingRequestCard(requests[index], service);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestCard(
      LeaveRequestModel request, LeaveManagementService service) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.8),
                      _accentColor.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${request.leaveType} (${request.dayType})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(request.status),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dates
                      _buildInfoRow(
                        Icons.date_range,
                        'Dates',
                        '${DateFormat('dd MMM').format(request.startDate.toDate())} to '
                            '${DateFormat('dd MMM').format(request.endDate.toDate())}',
                      ),
                      const SizedBox(height: 12),

                      // Duration
                      _buildInfoRow(
                        Icons.timelapse,
                        'Duration',
                        _calculateDuration(request.startDate.toDate(),
                            request.endDate.toDate()),
                      ),
                      const SizedBox(height: 12),

                      // Reason
                      _buildInfoRow(
                        Icons.comment,
                        'Reason',
                        request.reason,
                        expanded: true,
                      ),

                      const Spacer(),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Approve',
                              icon: Icons.check_circle,
                              color: _successColor,
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                try {
                                  await service.updateLeaveRequestStatus(
                                      request.leaveId, 'Approved');
                                  if (!mounted) return;
                                  _showSuccessSnackBar(
                                      'Leave request approved successfully');
                                  await _refreshRequests();
                                } catch (e) {
                                  if (!mounted) return;
                                  _showErrorSnackBar(
                                      'Failed to approve request: $e');
                                } finally {
                                  if (mounted)
                                    setState(() => _isLoading = false);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Reject',
                              icon: Icons.cancel,
                              color: _dangerColor,
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                try {
                                  await service.updateLeaveRequestStatus(
                                      request.leaveId, 'Rejected');
                                  if (!mounted) return;
                                  _showSuccessSnackBar(
                                      'Leave request rejected');
                                  await _refreshRequests();
                                } catch (e) {
                                  if (!mounted) return;
                                  _showErrorSnackBar(
                                      'Failed to reject request: $e');
                                } finally {
                                  if (mounted)
                                    setState(() => _isLoading = false);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = _successColor;
        break;
      case 'rejected':
        color = _dangerColor;
        break;
      default:
        color = _warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool expanded = false}) {
    return Row(
      crossAxisAlignment:
          expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimaryColor,
                ),
                maxLines: expanded ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  // ----------------------------------------------------
  //  Leave History Section
  // ----------------------------------------------------
  Widget _buildLeaveHistorySection(LeaveManagementService service) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Leave History', Icons.history),
          const SizedBox(height: 16),

          // Date selection card
          InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: _primaryColor,
                        onPrimary: Colors.white,
                        onSurface: _textPrimaryColor,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null && mounted) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textSecondaryColor,
                          ),
                        ),
                        Text(
                          selectedDate == null
                              ? 'Select a date to view leave requests'
                              : DateFormat.yMMMMd().format(selectedDate!),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedDate == null
                                ? _textSecondaryColor
                                : _textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Leave history list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FutureBuilder<List<LeaveRequestModel>>(
                  future: service.getLeaveRequestsForDate(selectedDate),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    } else if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(selectedDate == null
                          ? 'Please select a date to view leave requests'
                          : 'No leave requests found for the selected date');
                    } else {
                      return ListView.separated(
                        padding: const EdgeInsets.all(0),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return _buildHistoryListTile(snapshot.data![index]);
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListTile(LeaveRequestModel leave) {
    // Determine color based on status
    Color statusColor;
    IconData statusIcon;
    switch (leave.status.toLowerCase()) {
      case 'approved':
        statusColor = _successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = _dangerColor;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = _warningColor;
        statusIcon = Icons.access_time;
    }

    final start = DateFormat('dd MMM yyyy').format(leave.startDate.toDate());
    final end = DateFormat('dd MMM yyyy').format(leave.endDate.toDate());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              leave.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              leave.status,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            '${leave.leaveType} (${leave.dayType})',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From $start to $end',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${leave.reason}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: _textSecondaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (leave.approvedBy != null) ...[
            const SizedBox(height: 4),
            Text(
              'Approved by: ${leave.approvedBy}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
      isThreeLine: true,
    );
  }

  // ----------------------------------------------------
  //  Helper UI Components
  // ----------------------------------------------------
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading data...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: _dangerColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: _textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays + 1;
    return '$difference ${difference == 1 ? 'day' : 'days'}';
  }
}
