import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/attendance_service.dart';
import '../../services/organisation_service.dart';
// If your app doesn't use leaves, remove the next line and the leave references
import '../../services/leave_request_service.dart';

import '../../models/attendance_model.dart';
// If your app doesn't have leave, remove this
import '../../models/leave_request_model.dart';
import '../../models/branch_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with TickerProviderStateMixin {
  // Combined map: each day -> list of events (Attendance or Leave)
  final Map<DateTime, List<dynamic>> _events = {};

  // Current focus and selection in the calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Stats
  int _totalDays = 0;
  int _presentDays = 0;
  int _lateDays = 0;
  int _absentDays = 0;
  int _leaveDays = 0;

  // Current tab
  int _currentTabIndex = 0;
  late TabController _tabController;

  // Loading states
  bool _isLoading = true;
  String? _error;

  // We fetch the user's branch to determine lateness
  BranchModel? _userBranch;

  // Range selection
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

  // Chart data
  List<PieChartSectionData> _pieChartData = [];
  List<BarChartGroupData> _barChartData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _loadUserAttendanceData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Normalizes a date to year-month-day (no hours/mins/secs)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Entry point: fetch user branch (for lateness) and user attendance records
  /// Optionally fetch leaves if your app supports it
  Future<void> _loadUserAttendanceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No user is currently logged in.';
      });
      return;
    }

    try {
      // We need services
      final attendanceService =
          Provider.of<AttendanceService>(context, listen: false);
      final organisationService =
          Provider.of<OrganisationService>(context, listen: false);

      // If you do not use leaves, remove these lines
      final leaveRequestService =
          Provider.of<LeaveRequestService>(context, listen: false);

      // 1) Fetch user doc to get branchId
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
          _error = 'User document not found.';
        });
        return;
      }
      final data = userDoc.data();
      final branchId = data?['branchId'] as String?;
      if (branchId == null || branchId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'User has no assigned branch.';
        });
        return;
      }

      // 2) Fetch the branch settings
      _userBranch = await organisationService.getBranchById(branchId);
      if (_userBranch == null) {
        setState(() {
          _isLoading = false;
          _error = 'Branch not found or no branch data.';
        });
        return;
      }

      // 3) Fetch attendance records
      final allAttendance =
          await attendanceService.getUserAttendanceRecords(userId);

      // 4) If your app also uses leaves for normal users, fetch them:
      // remove if not needed
      final approvedLeaves =
          await leaveRequestService.getApprovedLeaveRequestsForUser(userId);

      // 5) Build the events map
      final Map<DateTime, List<dynamic>> tempEvents = {};

      // Populate attendance
      for (var record in allAttendance) {
        final day = _normalizeDate(record.clockIn.toDate());
        tempEvents.putIfAbsent(day, () => []).add(record);
      }

      // If you do leaves, populate them
      for (var leave in approvedLeaves) {
        final start = _normalizeDate(leave.startDate.toDate());
        final end = _normalizeDate(leave.endDate.toDate());
        for (DateTime d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))) {
          tempEvents.putIfAbsent(d, () => []).add(leave);
        }
      }

      // Calculate statistics for the last 30 days
      final today = _normalizeDate(DateTime.now());
      final thirtyDaysAgo = today.subtract(const Duration(days: 30));

      int present = 0;
      int late = 0;
      int absent = 0;
      int leave = 0;
      int total = 0;

      for (DateTime day = thirtyDaysAgo;
          !day.isAfter(today);
          day = day.add(const Duration(days: 1))) {
        // Skip weekends
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          continue;
        }

        total++;
        final events = tempEvents[day] ?? [];
        final status = _getDayStatus(day, events);

        switch (status) {
          case 'present':
            present++;
            break;
          case 'late':
            late++;
            break;
          case 'leave':
            leave++;
            break;
          case 'absent':
            absent++;
            break;
          default:
            break;
        }
      }

      setState(() {
        _events.clear();
        _events.addAll(tempEvents);
        _totalDays = total;
        _presentDays = present;
        _lateDays = late;
        _absentDays = absent;
        _leaveDays = leave;
        _isLoading = false;
        _error = null;

        // Prepare chart data
        _preparePieChartData();
        _prepareBarChartData();

        // Start animations
        _fadeController.forward();
        _slideController.forward();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading attendance data: $e';
      });
    }
  }

  /// Returns all events for the given day
  List<dynamic> _getEventsForDay(DateTime day) {
    final normalized = _normalizeDate(day);
    return _events[normalized] ?? [];
  }

  /// Decide the day's overall status:
  /// - If any leave => 'leave'
  /// - else if day is future => 'none'
  /// - else if no attendance => 'absent'
  /// - else if late => 'late'
  /// - else => 'present'
  String _getDayStatus(DateTime date, List<dynamic> events) {
    final normalized = _normalizeDate(date);
    final today = _normalizeDate(DateTime.now());

    // If there's a leave object in the events
    final hasLeave = events.any((e) => e is LeaveRequestModel);
    if (hasLeave) return 'leave';

    // If date is in the future with no events => 'none'
    if (normalized.isAfter(today) && events.isEmpty) {
      return 'none';
    }

    // Find earliest attendance record
    AttendanceModel? earliest;
    for (var e in events) {
      if (e is AttendanceModel) {
        if (earliest == null ||
            e.clockIn.toDate().isBefore(earliest.clockIn.toDate())) {
          earliest = e;
        }
      }
    }

    if (earliest == null) {
      return 'absent';
    }

    // check lateness
    final clockInTime = earliest.clockIn.toDate();
    final actualMinutes = clockInTime.hour * 60 + clockInTime.minute;
    final branchClockIn = _userBranch!.clockInMinutes;
    final buffer = _userBranch!.bufferMinutes;
    final allowed = branchClockIn + buffer;

    if (actualMinutes > allowed) {
      return 'late';
    } else {
      return 'present';
    }
  }

  /// Format timestamps for display
  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final date = ts.toDate().toLocal();
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  /// Check if two DateTimes are same day
  bool _sameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Duration _calculateDuration(AttendanceModel record) {
    if (record.clockOut != null) {
      final out = record.clockOut!.toDate();
      return out.difference(record.clockIn.toDate());
    }
    return Duration.zero;
  }

  void _calculateStats() {
    _totalDays = 0;
    _presentDays = 0;
    _lateDays = 0;
    _absentDays = 0;
    _leaveDays = 0;

    for (var day in _events.keys) {
      final events = _getEventsForDay(day);
      _totalDays++;
      final status = _getDayStatus(day, events);
      switch (status) {
        case 'present':
          _presentDays++;
          break;
        case 'late':
          _lateDays++;
          break;
        case 'absent':
          _absentDays++;
          break;
        case 'leave':
          _leaveDays++;
          break;
      }
    }
  }

  /// Prepares pie chart data based on attendance stats
  void _preparePieChartData() {
    _pieChartData = [
      PieChartSectionData(
        color: Colors.green.shade400,
        value: _presentDays.toDouble(),
        title: '$_presentDays',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange.shade400,
        value: _lateDays.toDouble(),
        title: '$_lateDays',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red.shade400,
        value: _absentDays.toDouble(),
        title: '$_absentDays',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.blue.shade400,
        value: _leaveDays.toDouble(),
        title: '$_leaveDays',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  /// Prepares bar chart data for weekly view
  void _prepareBarChartData() {
    final now = DateTime.now();
    _barChartData = [];

    // Get weekly data
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final events = _getEventsForDay(day);
      final dayStatus = _getDayStatus(day, events);

      double presentValue = 0;
      double lateValue = 0;
      double absentValue = 0;

      switch (dayStatus) {
        case 'present':
          presentValue = 1;
          break;
        case 'late':
          lateValue = 1;
          break;
        case 'absent':
          absentValue = 1;
          break;
        default:
          break;
      }

      _barChartData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: presentValue,
              color: Colors.green.shade400,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: lateValue,
              color: Colors.orange.shade400,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: absentValue,
              color: Colors.red.shade400,
              width: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your attendance data...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadUserAttendanceData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 200,
                        floating: false,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            'Attendance History',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.deepPurple.shade800,
                                  Colors.deepPurple.shade500,
                                ],
                              ),
                            ),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Icon(
                                      Icons.access_time,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        bottom: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.7),
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Calendar'),
                            Tab(text: 'Analytics'),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildCalendarTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewTab() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 30 Days Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        label: 'Present',
                        value: _presentDays,
                        color: Colors.green.shade400,
                        icon: Icons.check_circle,
                      ),
                      _buildStatItem(
                        label: 'Late',
                        value: _lateDays,
                        color: Colors.orange.shade400,
                        icon: Icons.access_time,
                      ),
                      _buildStatItem(
                        label: 'Absent',
                        value: _absentDays,
                        color: Colors.red.shade400,
                        icon: Icons.cancel,
                      ),
                      _buildStatItem(
                        label: 'Leave',
                        value: _leaveDays,
                        color: Colors.blue.shade400,
                        icon: Icons.beach_access,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance Rate:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_totalDays > 0 ? ((_presentDays / _totalDays) * 100).toStringAsFixed(1) : 0}%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recent activity
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Recent activity list
          _buildRecentActivityList(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Calendar view with customized style
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildModernCalendar(),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildLegend(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Selected day details
        if (_selectedDay != null) _buildModernDayDetails(_selectedDay!),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SlideTransition(
      position: _slideAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Attendance distribution chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Distribution',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 240,
                    child: PieChart(
                      PieChartData(
                        sections: _pieChartData,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Present', Colors.green.shade400),
                      _buildLegendItem('Late', Colors.orange.shade400),
                      _buildLegendItem('Absent', Colors.red.shade400),
                      _buildLegendItem('Leave', Colors.blue.shade400),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Weekly attendance chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 Days',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 240,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 1,
                        barGroups: _barChartData,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final weekday = DateTime.now()
                                    .subtract(Duration(days: value.toInt()))
                                    .weekday;
                                String day = '';

                                switch (weekday) {
                                  case 1:
                                    day = 'M';
                                    break;
                                  case 2:
                                    day = 'T';
                                    break;
                                  case 3:
                                    day = 'W';
                                    break;
                                  case 4:
                                    day = 'T';
                                    break;
                                  case 5:
                                    day = 'F';
                                    break;
                                  case 6:
                                    day = 'S';
                                    break;
                                  case 7:
                                    day = 'S';
                                    break;
                                }

                                return Text(
                                  day,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: 0.5,
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

  Widget _buildStatItem({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    // Get the most recent 5 days with events
    final List<DateTime> recentDays = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Sort days with events by date (most recent first)
    final sortedDays = _events.keys.where((date) {
      return date.isAfter(thirtyDaysAgo) && !date.isAfter(now);
    }).toList();

    sortedDays.sort((a, b) => b.compareTo(a));

    final List<DateTime> daysToShow = sortedDays.take(5).toList();

    if (daysToShow.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No recent attendance records',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: daysToShow.map((day) {
        final events = _getEventsForDay(day);
        final status = _getDayStatus(day, events);

        Color statusColor;
        IconData statusIcon;
        String statusText;

        switch (status) {
          case 'present':
            statusColor = Colors.green.shade400;
            statusIcon = Icons.check_circle;
            statusText = 'Present';
            break;
          case 'late':
            statusColor = Colors.orange.shade400;
            statusIcon = Icons.access_time;
            statusText = 'Late';
            break;
          case 'leave':
            statusColor = Colors.blue.shade400;
            statusIcon = Icons.beach_access;
            statusText = 'On Leave';
            break;
          case 'absent':
            statusColor = Colors.red.shade400;
            statusIcon = Icons.cancel;
            statusText = 'Absent';
            break;
          default:
            statusColor = Colors.grey.shade400;
            statusIcon = Icons.help;
            statusText = 'Unknown';
        }

        // Find attendance details if any
        AttendanceModel? attendance;
        for (var event in events) {
          if (event is AttendanceModel) {
            attendance = event;
            break;
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedDay = day;
                _focusedDay = day;
                _tabController.animateTo(1); // Switch to calendar tab
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMMd().format(day),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (attendance != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Clock In: ${DateFormat('hh:mm a').format(attendance.clockIn.toDate())}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernCalendar() {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
          _selectedDay != null && _isSameDay(day, _selectedDay!),
      eventLoader: (day) => _getEventsForDay(day),
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          size: 24,
          color: Colors.deepPurple,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          size: 24,
          color: Colors.deepPurple,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Colors.deepPurple.shade200,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.deepPurple,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        weekendTextStyle: const TextStyle(color: Colors.red),
        holidayTextStyle: const TextStyle(color: Colors.blue),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (ctx, date, events) {
          final status = _getDayStatus(date, events);
          if (status == 'none') {
            return const SizedBox();
          }
          Color color;
          switch (status) {
            case 'present':
              color = Colors.green;
              break;
            case 'late':
              color = Colors.orange;
              break;
            case 'leave':
              color = Colors.blue;
              break;
            case 'absent':
            default:
              color = Colors.red;
              break;
          }
          return Positioned(
            bottom: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernDayDetails(DateTime day) {
    final events = _getEventsForDay(day);

    // Separate attendance from leaves
    final attendanceEvents = <AttendanceModel>[];
    final leaveEvents = <LeaveRequestModel>[];

    for (var e in events) {
      if (e is AttendanceModel) {
        attendanceEvents.add(e);
      } else if (e is LeaveRequestModel) {
        leaveEvents.add(e);
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.deepPurple.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat.yMMMMd().format(day),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Attendance
            if (attendanceEvents.isNotEmpty) ...[
              Text(
                'Attendance',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...attendanceEvents.map(_buildModernAttendanceCard).toList(),
              const SizedBox(height: 16),
            ],

            // Leaves
            if (leaveEvents.isNotEmpty) ...[
              Text(
                'Approved Leave',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...leaveEvents.map(_buildModernLeaveCard).toList(),
            ],

            // If none
            if (attendanceEvents.isEmpty && leaveEvents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No records for this day',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAttendanceCard(AttendanceModel record) {
    final clockInDate = record.clockIn.toDate();
    final clockOutDate = record.clockOut?.toDate();
    final clockInStr = DateFormat('hh:mm a').format(clockInDate);
    final clockOutStr = clockOutDate == null
        ? 'N/A'
        : DateFormat('hh:mm a').format(clockOutDate);
    final isDifferentDay =
        clockOutDate != null && !_sameDay(clockInDate, clockOutDate);
    final duration = _calculateDuration(record);

    // Check lateness
    final actualClockInMinutes = clockInDate.hour * 60 + clockInDate.minute;
    final branchClockInMinutes = _userBranch!.clockInMinutes;
    final buffer = _userBranch!.bufferMinutes;
    final allowedMinutes = branchClockInMinutes + buffer;
    final isLate = actualClockInMinutes > allowedMinutes;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isLate ? Colors.orange.shade50 : Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLate ? Icons.access_time : Icons.check_circle,
                    color: isLate ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLate ? 'Late Arrival' : 'On Time',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration.inHours > 0
                          ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                          : '${duration.inMinutes}m',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn(
                  label: 'Clock In',
                  time: clockInStr,
                  icon: Icons.login,
                  color: Colors.blue,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildTimeColumn(
                  label: 'Clock Out',
                  time: clockOutStr,
                  icon: Icons.logout,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModernLeaveCard(LeaveRequestModel leave) {
    final start = DateFormat.yMMMMd().format(leave.startDate.toDate());
    final end = DateFormat.yMMMMd().format(leave.endDate.toDate());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.beach_access,
                    color: Colors.blue.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${leave.leaveType} (${leave.dayType})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Approved',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        start,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        end,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              leave.reason,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: [
          _buildLegendItem('Present', Colors.green.shade400),
          _buildLegendItem('Late', Colors.orange.shade400),
          _buildLegendItem('Absent', Colors.red.shade400),
          _buildLegendItem('Leave', Colors.blue.shade400),
        ],
      ),
    );
  }
}
