import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import screens
import 'team_performance_screen.dart';
import 'task_approval_screen.dart';
import 'customer_task_data_screen.dart';
import '../common/attendance_history_screen.dart';
import '../common/user_todo_task_list_screen.dart';
import '../common/leave_request_form.dart';
import '../sales_staff/enquiry_list_screen.dart';
import '../sales_staff/job_enquiry_screen.dart';
import '../sales_staff/sales_data_entry_screen.dart';
import '../sales_staff/sales_order_history_screen.dart';

// Import custom widgets
import '../../widgets/modern_profile_section.dart';
import '../../widgets/modern_announcement_card.dart';
import '../../widgets/modern_dashboard_tile.dart';
import '../../widgets/modern_clock_in_out_button.dart';

// Import providers
import '../../providers/announcement_provider.dart';
import '../../providers/user_provider.dart';

// Import localization
import '../../l10n/app_localizations.dart';

class UserPerformance {
  final String userId;
  final String name;
  final String role;
  final String imageUrl;
  final int completedTasks;
  final int totalTasks;
  final double performance;

  UserPerformance({
    required this.userId,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.completedTasks,
    required this.totalTasks,
    required this.performance,
  });
}

class ModernManagerDashboard extends StatefulWidget {
  const ModernManagerDashboard({super.key});

  @override
  State<ModernManagerDashboard> createState() => _ModernManagerDashboardState();
}

class _ModernManagerDashboardState extends State<ModernManagerDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  final List<Map<String, dynamic>> _dashboardItems = [];
  final List<UserPerformance> _teamPerformance = [];
  bool _isLoading = true;

  // Statistics that will be loaded from Firestore
  int _totalUsers = 0;
  int _totalTasks = 0;
  int _pendingApprovals = 0;
  int _completedTasks = 0;

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
        'title': 'Team Performance',
        'icon': Icons.assessment,
        'color': const Color(0xFF6C63FF),
        'screen': const TeamPerformanceScreen(),
        'isNew': true,
      },
      {
        'title': 'Task Approvals',
        'icon': Icons.check_circle,
        'color': const Color(0xFF4ECDC4),
        'screen': const TaskApprovalScreen(),
        'count': _pendingApprovals,
      },
      {
        'title': 'To-do List',
        'icon': Icons.work_outline,
        'color': const Color(0xFFFF9D97),
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
        'color': const Color(0xFFFFC75F),
        'screen': const EnquiryListScreen(),
      },
      {
        'title': 'Sales Data Entry',
        'icon': Icons.edit_note,
        'color': const Color(0xFF5CC281),
        'screen': const SalesDataEntryScreen(),
      },
      {
        'title': 'Enquiry History',
        'icon': Icons.storage_rounded,
        'color': const Color(0xFF5DADE2),
        'screen': const SalesOrderHistoryScreen(),
      },
      {
        'title': 'Customer Task Data',
        'icon': Icons.data_usage,
        'color': const Color(0xFFFC7676),
        'screen': const CustomerTaskDataScreen(),
      },
      {
        'title': 'Leave Requests',
        'icon': Icons.time_to_leave,
        'color': const Color(0xFF9B59B6),
        'screen': const LeaveRequestForm(),
      },
      {
        'title': 'Attendance',
        'icon': Icons.access_time,
        'color': const Color(0xFFE77E23),
        'screen': const AttendanceHistoryScreen(),
      },
    ]);
  }

  Future<void> _loadDashboardStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user count
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();
      _totalUsers = usersSnapshot.size;

      // Load task count
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: 'staff')
          .get();
      _totalTasks = tasksSnapshot.size;

      // Load pending approvals
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('todoTasks')
          .where('status', isEqualTo: 'Pending Approval')
          .get();
      _pendingApprovals = pendingSnapshot.size;

      // Load completed tasks
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('todoTasks')
          .where('status', isEqualTo: 'Completed')
          .get();
      _completedTasks = completedSnapshot.size;

      // Load team performance data
      await _loadTeamPerformance();
    } catch (e) {
      debugPrint('Error loading dashboard statistics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamPerformance() async {
    // Dummy data - in a real app, this would be loaded from Firestore
    _teamPerformance.clear();
    _teamPerformance.addAll([
      UserPerformance(
        userId: '1',
        name: 'John Doe',
        role: 'Sales Representative',
        imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        completedTasks: 28,
        totalTasks: 32,
        performance: 87,
      ),
      UserPerformance(
        userId: '2',
        name: 'Jane Smith',
        role: 'Marketing Specialist',
        imageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        completedTasks: 18,
        totalTasks: 20,
        performance: 92,
      ),
      UserPerformance(
        userId: '3',
        name: 'Mark Johnson',
        role: 'Support Agent',
        imageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        completedTasks: 15,
        totalTasks: 25,
        performance: 65,
      ),
      UserPerformance(
        userId: '4',
        name: 'Sarah Wilson',
        role: 'Sales Representative',
        imageUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
        completedTasks: 22,
        totalTasks: 24,
        performance: 90,
      ),
    ]);
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
                            _buildMenuItem(
                                'Team', Icons.people, 1, _selectedIndex == 1),
                            _buildMenuHeader('Management', _isSidebarExpanded),
                            _buildMenuItem('Tasks', Icons.task_alt, 2, false),
                            _buildMenuItem(
                                'Approvals', Icons.check_circle, 3, false),
                            _buildMenuItem(
                                'Attendance', Icons.access_time, 4, false),
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
                    const ModernAnnouncementCard(role: 'manager'),

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

                            // Team Performance tab
                            buildTeamTab(size, isMobile),
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
                        'Manager Dashboard',
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
                        'Team Members',
                        _totalUsers.toString(),
                        Icons.people,
                        Colors.blueAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Total Tasks',
                        _totalTasks.toString(),
                        Icons.task_alt,
                        Colors.orangeAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Pending Approvals',
                        _pendingApprovals.toString(),
                        Icons.pending_actions,
                        Colors.redAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Completed Tasks',
                        _completedTasks.toString(),
                        Icons.check_circle_outline,
                        Colors.greenAccent,
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

  Widget buildTeamTab(Size size, bool isMobile) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Performance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor your team members\' performance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final performance = _teamPerformance[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: CachedNetworkImageProvider(
                          performance.imageUrl,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              performance.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              performance.role,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: performance.performance / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getColorForPerformance(
                                    performance.performance),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${performance.performance.toInt()}% Performance',
                                  style: TextStyle(
                                    color: _getColorForPerformance(
                                        performance.performance),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${performance.completedTasks}/${performance.totalTasks} Tasks',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: _teamPerformance.length,
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
                'Team Members',
                _totalUsers.toString(),
                Icons.people,
                Colors.blueAccent,
                _isLoading,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Total Tasks',
                _totalTasks.toString(),
                Icons.task_alt,
                Colors.orangeAccent,
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
                'Pending Approvals',
                _pendingApprovals.toString(),
                Icons.pending_actions,
                Colors.redAccent,
                _isLoading,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Completed Tasks',
                _completedTasks.toString(),
                Icons.check_circle_outline,
                Colors.greenAccent,
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

  Color _getColorForPerformance(double performance) {
    if (performance >= 90) {
      return Colors.green;
    } else if (performance >= 75) {
      return Colors.lightGreen;
    } else if (performance >= 50) {
      return Colors.amber;
    } else {
      return Colors.redAccent;
    }
  }
}
