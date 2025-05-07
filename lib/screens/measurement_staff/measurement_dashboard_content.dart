import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_emp/screens/common/user_todo_task_list_screen.dart';
import 'package:z_emp/screens/sales_staff/enquiry_list_screen.dart';
import 'package:z_emp/screens/sales_staff/job_enquiry_screen.dart';
import 'package:z_emp/screens/sales_staff/sales_data_entry_screen.dart';
import 'package:z_emp/screens/sales_staff/sales_order_history_screen.dart';
import '../../widgets/modern_profile_section.dart';
import '../../widgets/modern_dashboard_tile.dart';
import '../../widgets/modern_announcement_card.dart';
import '../../widgets/modern_clock_in_out_button.dart';
import 'task_logging_screen.dart';
import '../common/leave_request_form.dart';
import '../common/salary_advance_screen.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/user_provider.dart';
import 'package:z_emp/screens/common/attendance_history_screen.dart';
import '../../l10n/app_localizations.dart';

class ModernMeasurementDashboard extends StatefulWidget {
  const ModernMeasurementDashboard({super.key});

  @override
  State<ModernMeasurementDashboard> createState() =>
      _ModernMeasurementDashboardState();
}

class _ModernMeasurementDashboardState extends State<ModernMeasurementDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  bool _isLoading = true;

  // Statistics that will be loaded from Firestore
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _measurementsToday = 0;

  final List<Map<String, dynamic>> _dashboardItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });

    _initializeDashboardItems();
    _loadDashboardStatistics();
  }

  void _initializeDashboardItems() {
    _dashboardItems.addAll([
      {
        'title': 'Log Task',
        'icon': Icons.task_alt,
        'color': const Color(0xFF6C63FF),
        'screen': const TaskLoggingScreen(),
      },
      {
        'title': 'To-do List',
        'icon': Icons.work_outline,
        'color': const Color(0xFF4ECDC4),
        'screen': const UserTodoTaskListScreen(),
      },
      {
        'title': 'Job Enquiries',
        'icon': Icons.work_outline,
        'color': const Color(0xFF7158E2),
        'screen': const JobEnquiryScreen(),
      },
      {
        'title': 'Enquiry List',
        'icon': Icons.follow_the_signs,
        'color': const Color(0xFFFF9D97),
        'screen': const EnquiryListScreen(),
      },
      {
        'title': 'Sales Data Entry',
        'icon': Icons.edit_note,
        'color': const Color(0xFFFFC75F),
        'screen': const SalesDataEntryScreen(),
      },
      {
        'title': 'Enquiry History',
        'icon': Icons.storage_rounded,
        'color': const Color(0xFF5CC281),
        'screen': const SalesOrderHistoryScreen(),
      },
      {
        'title': 'Leave Requests',
        'icon': Icons.time_to_leave,
        'color': const Color(0xFF5DADE2),
        'screen': const LeaveRequestForm(),
      },
      {
        'title': 'Salary Advance',
        'icon': Icons.attach_money,
        'color': const Color(0xFFFC7676),
        'screen': const SalaryAdvanceScreen(),
      },
      {
        'title': 'Attendance',
        'icon': Icons.access_time,
        'color': const Color(0xFF9B59B6),
        'screen': const AttendanceHistoryScreen(),
      },
    ]);
  }

  Future<void> _loadDashboardStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get today's date at 00:00:00
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Load measurement staff tasks count
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: 'measurement')
          .get();
      _totalTasks = tasksSnapshot.size;

      // Load completed tasks
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: 'measurement')
          .where('status', isEqualTo: 'Completed')
          .get();
      _completedTasks = completedSnapshot.size;

      // Load pending tasks
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: 'measurement')
          .where('status', isEqualTo: 'Pending')
          .get();
      _pendingTasks = pendingSnapshot.size;

      // Load today's measurements
      final todaySnapshot = await FirebaseFirestore.instance
          .collection('measurements')
          .where('createdAt', isGreaterThanOrEqualTo: today)
          .get();
      _measurementsToday = todaySnapshot.size;
    } catch (e) {
      debugPrint('Error loading dashboard statistics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Provider.of<AnnouncementProvider>(context, listen: false)
        .fetchAnnouncements();
    await _loadDashboardStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = Provider.of<UserProvider>(context).user;
    final appLocalization = AppLocalizations.of(context);
    final isDesktop = size.width >= 1100;
    final isTablet = size.width >= 650 && size.width < 1100;
    final isMobile = size.width < 650;

    // Auto collapse sidebar on mobile and tablet in portrait mode
    if (isMobile || (isTablet && size.height > size.width)) {
      _isSidebarExpanded = false;
    }

    return Scaffold(
      body: Container(
        color: const Color(0xFFF9FAFE),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar - Only show on tablet and desktop
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSidebarExpanded ? 250 : 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                            if (_isSidebarExpanded) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Z-EMP',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(
                        color: Color(0xFF3A3F51),
                        height: 1,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          children: [
                            _buildMenuHeader('Main', _isSidebarExpanded),
                            _buildMenuItem('Dashboard', Icons.dashboard, 0,
                                _selectedIndex == 0),
                            _buildMenuItem('Analytics', Icons.analytics, 1,
                                _selectedIndex == 1),
                            _buildMenuHeader('Tasks', _isSidebarExpanded),
                            _buildMenuItem(
                                'Log Task', Icons.task_alt, 2, false),
                            _buildMenuItem(
                                'To-do List', Icons.list_alt, 3, false),
                            _buildMenuItem(
                                'Enquiries', Icons.question_answer, 4, false),
                          ],
                        ),
                      ),
                      const Divider(
                        color: Color(0xFF3A3F51),
                        height: 1,
                      ),
                      if (!isMobile && !isTablet)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isSidebarExpanded = !_isSidebarExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: _isSidebarExpanded
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isSidebarExpanded
                                        ? Icons.keyboard_arrow_left
                                        : Icons.keyboard_arrow_right,
                                    color: Colors.white,
                                  ),
                                  if (_isSidebarExpanded) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Collapse',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile section
                    ModernProfileSection(showLogout: !isMobile),

                    // Announcement card
                    const ModernAnnouncementCard(role: 'measurement'),

                    // Clock in/out button
                    const ModernClockInOutButton(),

                    // Main content with tabs
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Dashboard tab
                            buildDashboardTab(
                                size, isDesktop, isTablet, isMobile),

                            // Analytics tab
                            buildAnalyticsTab(size, isMobile),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuHeader(String title, bool expanded) {
    if (!expanded) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      String title, IconData icon, int index, bool isSelected) {
    return InkWell(
      onTap: () {
        if (index <= 1) {
          _tabController.animateTo(index);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDashboardTab(
      Size size, bool isDesktop, bool isTablet, bool isMobile) {
    // Determine grid count based on screen size
    int crossAxisCount = isDesktop
        ? 4
        : isTablet
            ? 3
            : 2;
    double childAspectRatio = isDesktop
        ? 1.2
        : isTablet
            ? 1.1
            : 1.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Measurement Dashboard',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 18 : null,
                                ),
                      ),
                    ),
                    if (!isMobile)
                      OutlinedButton.icon(
                        onPressed: _handleRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Statistics cards - adjust layout for different screen sizes
                if (isMobile)
                  _buildMobileStatCards()
                else
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Tasks',
                        _totalTasks.toString(),
                        Icons.assignment,
                        Colors.blueAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Completed Tasks',
                        _completedTasks.toString(),
                        Icons.check_circle,
                        Colors.greenAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Pending Tasks',
                        _pendingTasks.toString(),
                        Icons.pending_actions,
                        Colors.orangeAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Today\'s Measurements',
                        _measurementsToday.toString(),
                        Icons.straighten,
                        Colors.purpleAccent,
                        _isLoading,
                      ),
                    ],
                  ),

                const SizedBox(height: 30),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : null,
                      ),
                ),
              ],
            ),
          ),
        ),

        // Dashboard tiles grid - responsive grid count
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: 10,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: isMobile ? 12 : 20,
              mainAxisSpacing: isMobile ? 12 : 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _dashboardItems[index];
                return ModernDashboardTile(
                  title: item['title'],
                  icon: item['icon'],
                  color: item['color'],
                  count: item['count'],
                  isNew: item['isNew'] ?? false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item['screen']),
                  ),
                );
              },
              childCount: _dashboardItems.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAnalyticsTab(Size size, bool isMobile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurement Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Task Completion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildAnalyticsChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                _buildPerformanceItem(
                  'Task Completion Rate',
                  _totalTasks > 0
                      ? (_completedTasks / _totalTasks * 100).round()
                      : 0,
                  Colors.blue,
                  '$_completedTasks/$_totalTasks Tasks',
                ),
                const SizedBox(height: 16),
                _buildPerformanceItem(
                  'Average Time Per Measurement',
                  85,
                  Colors.green,
                  '25 minutes',
                ),
                const SizedBox(height: 16),
                _buildPerformanceItem(
                  'Accuracy Rating',
                  92,
                  Colors.orange,
                  '92%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    // Placeholder for a chart
    // Ideally you would use fl_chart or charts_flutter package
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Tasks Chart - Replace with actual chart implementation'),
      ),
    );
  }

  Widget _buildPerformanceItem(
      String title, int progressPercent, Color color, String detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  // Mobile-specific layout for stat cards
  Widget _buildMobileStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Tasks',
                _totalTasks.toString(),
                Icons.assignment,
                Colors.blueAccent,
                _isLoading,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Completed',
                _completedTasks.toString(),
                Icons.check_circle,
                Colors.greenAccent,
                _isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                _pendingTasks.toString(),
                Icons.pending_actions,
                Colors.orangeAccent,
                _isLoading,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Today',
                _measurementsToday.toString(),
                Icons.straighten,
                Colors.purpleAccent,
                _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Responsive stat card with simplified layout for mobile
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isLoading) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Row(
          children: [
            Container(
              width: isMobile ? 40 : 60,
              height: isMobile ? 40 : 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 20 : 30,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 12 : null,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 4 : 8),
                  isLoading
                      ? Container(
                          width: 60,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : null,
                              ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Original MeasurementDashboardContent class remains for backward compatibility
class MeasurementDashboardContent extends StatefulWidget {
  const MeasurementDashboardContent({super.key});

  @override
  State<MeasurementDashboardContent> createState() =>
      _MeasurementDashboardContentState();
}

class _MeasurementDashboardContentState
    extends State<MeasurementDashboardContent> {
  @override
  Widget build(BuildContext context) {
    // Return the new modern dashboard instead
    return const ModernMeasurementDashboard();
  }
}
