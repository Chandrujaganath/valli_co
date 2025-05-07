// lib/screens/admin/user_attendance_detail_screen.dart

// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_request_service.dart';
import '../../services/organisation_service.dart';
import '../../models/attendance_model.dart';
import '../../models/leave_request_model.dart';
import '../../models/branch_model.dart';
import 'package:intl/intl.dart';

class UserAttendanceDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserAttendanceDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  _UserAttendanceDetailScreenState createState() =>
      _UserAttendanceDetailScreenState();
}

class _UserAttendanceDetailScreenState extends State<UserAttendanceDetailScreen>
    with TickerProviderStateMixin {
  // Combined events map: DateTime -> List<dynamic> (AttendanceModel or LeaveRequestModel)
  Map<DateTime, List<dynamic>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Stats for analytics
  int _totalDays = 0;
  int _presentDays = 0;
  int _lateDays = 0;
  int _absentDays = 0;
  int _leaveDays = 0;

  // Chart data
  List<PieChartSectionData> _pieChartData = [];
  List<BarChartGroupData> _barChartData = [];

  // Branch settings - with default values to prevent crashes
  BranchModel? _userBranch;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    // Initialize animation controllers
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

    _loadEvents();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final attendanceService =
        Provider.of<AttendanceService>(context, listen: false);
    final leaveRequestService =
        Provider.of<LeaveRequestService>(context, listen: false);
    final organisationService =
        Provider.of<OrganisationService>(context, listen: false);

    try {
      // Fetch user's document to get branchId
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!userDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'User not found. Please check if the user still exists.';
        });
        return;
      }

      final branchId = userDoc.data()?['branchId'] as String?;
      if (branchId == null || branchId.isEmpty) {
        print('User branch not set for user: ${widget.userId}');

        // Create a default branch model to prevent crashes
        _userBranch = BranchModel(
          branchId: 'default',
          name: 'Default Branch',
          address: 'Default Address',
          clockInMinutes: 540, // 9:00 AM
          bufferMinutes: 15,
        );

        // Show warning but continue loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User branch not set. Using default settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Try to fetch branch settings
        try {
          _userBranch = await organisationService.getBranchById(branchId);
        } catch (e) {
          print('Error fetching branch: $e');
        }

        // If branch not found, use default settings
        if (_userBranch == null) {
          print('Branch not found for ID: $branchId. Using default settings.');
          _userBranch = BranchModel(
            branchId: 'default',
            name: 'Default Branch',
            address: 'Default Address',
            clockInMinutes: 540, // 9:00 AM
            bufferMinutes: 15,
          );

          // Show warning but continue loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Branch not found (ID: $branchId). Using default settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Fetch attendance records
      final attendanceRecords =
          await attendanceService.getUserAttendanceRecords(widget.userId);
      print('Fetched Attendance Records: ${attendanceRecords.length}');

      // Fetch approved leave records
      final leaveRecords = await leaveRequestService
          .getApprovedLeaveRequestsForUser(widget.userId);
      print('Fetched Approved Leave Records: ${leaveRecords.length}');

      // Initialize events map
      Map<DateTime, List<dynamic>> events = {};

      // Populate attendance events
      for (var record in attendanceRecords) {
        DateTime date = _normalizeDate(record.clockIn.toDate());
        events.putIfAbsent(date, () => []).add(record);
      }

      // Populate leave events
      for (var leave in leaveRecords) {
        DateTime start = _normalizeDate(leave.startDate.toDate());
        DateTime end = _normalizeDate(leave.endDate.toDate());
        // Iterate each day in the leave period
        for (DateTime date = start;
            !date.isAfter(end);
            date = date.add(const Duration(days: 1))) {
          events.putIfAbsent(date, () => []).add(leave);
        }
      }

      // Calculate attendance statistics
      _calculateStats(events);
      _preparePieChartData();
      _prepareBarChartData();

      setState(() {
        _events = events;
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attendance data: $e';
      });
    }
  }

  void _calculateStats(Map<DateTime, List<dynamic>> events) {
    _totalDays = 0;
    _presentDays = 0;
    _lateDays = 0;
    _absentDays = 0;
    _leaveDays = 0;

    // Get date range for the last 30 days
    final today = _normalizeDate(DateTime.now());
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    for (DateTime day = thirtyDaysAgo;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))) {
      // Skip weekends
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        continue;
      }

      _totalDays++;
      final dayEvents = events[day] ?? [];
      final status = _getDayStatus(day, dayEvents);

      switch (status) {
        case 'present':
          _presentDays++;
          break;
        case 'late':
          _lateDays++;
          break;
        case 'leave':
          _leaveDays++;
          break;
        case 'absent':
          _absentDays++;
          break;
        default:
          break;
      }
    }
  }

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

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return _events[normalizedDay] ?? [];
  }

  /// Determine a single status for the given day based on events:
  /// Priority: leave > late > present > absent
  String _getDayStatus(DateTime date, List<dynamic> events) {
    DateTime normalizedDate = _normalizeDate(date);
    DateTime today = _normalizeDate(DateTime.now());

    // If there's a leave on this date, mark as leave
    bool hasLeave = events.any((e) => e is LeaveRequestModel);
    if (hasLeave) return 'leave';

    // Future date with no events => none
    if (normalizedDate.isAfter(today) && events.isEmpty) {
      return 'none';
    }

    // For past or current day, figure out attendance
    AttendanceModel? earliestRecord;
    for (var event in events) {
      if (event is AttendanceModel) {
        if (earliestRecord == null ||
            event.clockIn.toDate().isBefore(earliestRecord.clockIn.toDate())) {
          earliestRecord = event;
        }
      }
    }

    // No attendance => absent
    if (earliestRecord == null) {
      return 'absent';
    }

    // Check for late - make sure we have branch settings
    if (_userBranch != null) {
      final clockInTime = earliestRecord.clockIn.toDate();
      final actualClockInMinutes = clockInTime.hour * 60 + clockInTime.minute;
      final branchClockInMinutes = _userBranch!.clockInMinutes;
      final bufferMinutes = _userBranch!.bufferMinutes;
      final allowedClockInMinutes = branchClockInMinutes + bufferMinutes;

      if (actualClockInMinutes > allowedClockInMinutes) {
        return 'late';
      }
    }

    return 'present';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    // Updated to a more detailed format
    return DateFormat('yyyy-MM-dd hh:mm a')
        .format(timestamp.toDate().toLocal());
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat.yMMMMd().format(timestamp.toDate().toLocal());
  }

  Duration _calculateDuration(AttendanceModel record) {
    if (record.clockOut != null) {
      return record.clockOut!.toDate().difference(record.clockIn.toDate());
    }
    return Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading attendance data...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
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
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadEvents,
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
                        expandedHeight: 150,
                        floating: false,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            '${widget.userName}\'s Attendance',
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
                                      size: 60,
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      children: [
        _buildLegendItem('Present', Colors.green.shade400),
        _buildLegendItem('Late', Colors.orange.shade400),
        _buildLegendItem('Absent', Colors.red.shade400),
        _buildLegendItem('Leave', Colors.blue.shade400),
      ],
    );
  }

  Widget _buildModernCalendar() {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
          _selectedDay != null && _isSameDay(day, _selectedDay!),
      eventLoader: _getEventsForDay,
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
        clockOutDate != null && !_isSameDay(clockInDate, clockOutDate);
    final duration = _calculateDuration(record);

    // Check lateness - using safe access to userBranch
    bool isLate = false;
    if (_userBranch != null) {
      final actualClockInMinutes = clockInDate.hour * 60 + clockInDate.minute;
      final branchClockInMinutes = _userBranch!.clockInMinutes;
      final buffer = _userBranch!.bufferMinutes;
      final allowedMinutes = branchClockInMinutes + buffer;
      isLate = actualClockInMinutes > allowedMinutes;
    }

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

  Widget _buildRecentActivityList() {
    // Get the most recent 5 days with events
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Sort days with events by date (most recent first)
    final sortedDays = _events.keys.where((date) {
      return date.isAfter(thirtyDaysAgo) && !date.isAfter(now);
    }).toList();

    sortedDays.sort((a, b) => b.compareTo(a));

    final daysToShow = sortedDays.take(5).toList();

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
}
