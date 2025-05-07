import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_emp/providers/announcement_provider.dart';
import 'package:z_emp/providers/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';

// Import screens
import 'admin_todo_task_assignment_screen.dart';
import 'admin_todo_task_list_screen.dart';
import 'admin_todo_task_history_screen.dart';
import 'announcement_management_screen.dart';
import 'user_management_screen.dart';
import 'enquiry_management_screen.dart';
import 'leave_management_screen.dart';
import 'salary_advance_management_screen.dart';
import 'attendance_overview_screen.dart';
import 'report_generation_screen.dart';
import 'organisation_management_screen.dart';
import 'product_management_screen.dart';
import 'geo_fence_management_screen.dart';

// Import custom widgets
import '../../widgets/modern_profile_section.dart';
import '../../widgets/modern_announcement_card.dart';
import '../../widgets/modern_dashboard_tile.dart';

// Import localization
import '../../l10n/app_localizations.dart';

class ModernAdminDashboard extends StatefulWidget {
  const ModernAdminDashboard({super.key});

  @override
  State<ModernAdminDashboard> createState() => _ModernAdminDashboardState();
}

class _ModernAdminDashboardState extends State<ModernAdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  final List<Color> _gradientColors = const [
    Color(0xFF5CE1E6),
    Color(0xFF38B6FF),
  ];

  // Statistics that will be loaded from Firestore
  int _totalUsers = 0;
  int _totalTasks = 0;
  int _totalEnquiries = 0;
  int _pendingApprovals = 0;
  bool _isLoading = true;

  // Scaffold key for drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });

    _loadDashboardStatistics();
  }

  Future<void> _loadDashboardStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user count
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.size;

      // Load task count
      final tasksSnapshot =
          await FirebaseFirestore.instance.collection('tasks').get();
      _totalTasks = tasksSnapshot.size;

      // Load enquiries count
      final enquiriesSnapshot =
          await FirebaseFirestore.instance.collection('enquiries').get();
      _totalEnquiries = enquiriesSnapshot.size;

      // Load pending approvals
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('todoTasks')
          .where('status', isEqualTo: 'Pending Approval')
          .get();
      _pendingApprovals = pendingSnapshot.size;
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

    // Create dashboard items with translations
    final dashboardItems = [
      {
        'title': appLocalization?.translate('to_do') ?? 'ToDo',
        'icon': Icons.task_rounded,
        'color': const Color(0xFF6C63FF),
        'screen': const AdminTodoTaskAssignmentScreen(),
        'count': _pendingApprovals,
      },
      {
        'title': appLocalization?.translate('to_do_list') ?? 'ToDo List',
        'icon': Icons.task_alt,
        'color': const Color(0xFF4ECDC4),
        'screen': const AdminTodoTaskListScreen(),
      },
      {
        'title': appLocalization?.translate('to_do_history') ?? 'ToDo History',
        'icon': Icons.history,
        'color': const Color(0xFF7158E2),
        'screen': const AdminTodoTaskHistoryScreen(),
      },
      {
        'title': appLocalization?.translate('enquiries') ?? 'Enquiries',
        'icon': Icons.question_answer,
        'color': const Color(0xFFFF9D97),
        'screen': const EnquiryManagementScreen(),
        'count': _totalEnquiries > 0 ? _totalEnquiries : null,
      },
      {
        'title':
            appLocalization?.translate('leave_requests') ?? 'Leave Requests',
        'icon': Icons.beach_access,
        'color': const Color(0xFFFFC75F),
        'screen': const LeaveManagementScreen(),
      },
      {
        'title':
            appLocalization?.translate('salary_advances') ?? 'Salary Advances',
        'icon': Icons.attach_money,
        'color': const Color(0xFF5CC281),
        'screen': const SalaryAdvanceManagementScreen(),
      },
      {
        'title': appLocalization?.translate('attendance') ?? 'Attendance',
        'icon': Icons.access_time,
        'color': const Color(0xFF4F4F4F),
        'screen': const AttendanceOverviewScreen(),
      },
      {
        'title': appLocalization?.translate('geo_fence') ?? 'Geo Fence',
        'icon': Icons.my_location,
        'color': const Color(0xFF5DADE2),
        'screen': const GeoFenceManagementScreen(),
        'isNew': true,
      },
      {
        'title': appLocalization?.translate('announcements') ?? 'Announcements',
        'icon': Icons.announcement,
        'color': const Color(0xFFFC7676),
        'screen': const AnnouncementManagementScreen(),
      },
      {
        'title': appLocalization?.translate('users') ?? 'Users',
        'icon': Icons.people,
        'color': const Color(0xFF9B59B6),
        'screen': const UserManagementScreen(),
        'count': _totalUsers > 0 ? _totalUsers : null,
      },
      {
        'title': appLocalization?.translate('reports') ?? 'Reports',
        'icon': Icons.insert_drive_file,
        'color': const Color(0xFFE77E23),
        'screen': const ReportGenerationScreen(),
      },
      {
        'title': appLocalization?.translate('organisation') ?? 'Organisation',
        'icon': Icons.business,
        'color': const Color(0xFF2C3E50),
        'screen': const OrganisationManagementScreen(),
      },
      {
        'title': appLocalization?.translate('products') ?? 'Products',
        'icon': Icons.inventory,
        'color': const Color(0xFF8E44AD),
        'screen': const ProductManagementScreen(),
      },
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? _buildDrawer(context) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF2A2D3E),
              title: Text(
                'Z-EMP',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _handleRefresh,
                ),
              ],
            )
          : null,
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
                        color: Colors.black.withValues(alpha: 13),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
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
                            _buildMenuItem('Statistics', Icons.bar_chart, 1,
                                _selectedIndex == 1),
                            _buildMenuItem('Settings', Icons.settings, 2,
                                _selectedIndex == 2),
                            _buildMenuHeader('Management', _isSidebarExpanded),
                            _buildMenuItem('Users', Icons.people, 3, false),
                            _buildMenuItem('Tasks', Icons.task_alt, 4, false),
                            _buildMenuItem(
                                'Products', Icons.inventory, 5, false),
                            _buildMenuHeader('Reports', _isSidebarExpanded),
                            _buildMenuItem(
                                'Analytics', Icons.analytics, 6, false),
                            _buildMenuItem(
                                'Exports', Icons.file_download, 7, false),
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
                    const ModernAnnouncementCard(role: 'admin'),

                    // Main content with tabs
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Dashboard tab
                            buildDashboardTab(dashboardItems, size, isDesktop,
                                isTablet, isMobile),

                            // Statistics tab
                            buildStatisticsTab(),

                            // Settings tab
                            const Center(child: Text('Settings')),
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
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: const Icon(Icons.menu),
            )
          : null,
    );
  }

  // Drawer for mobile view
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF2A2D3E),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1F1D2B),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Z-EMP Admin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    'Dashboard',
                    Icons.dashboard,
                    0,
                    _selectedIndex == 0,
                  ),
                  _buildDrawerItem(
                    context,
                    'Statistics',
                    Icons.bar_chart,
                    1,
                    _selectedIndex == 1,
                  ),
                  _buildDrawerItem(
                    context,
                    'Settings',
                    Icons.settings,
                    2,
                    _selectedIndex == 2,
                  ),
                  const Divider(color: Colors.white24),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'Management',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDrawerItem(context, 'Users', Icons.people, 3, false),
                  _buildDrawerItem(context, 'Tasks', Icons.task_alt, 4, false),
                  _buildDrawerItem(
                      context, 'Products', Icons.inventory, 5, false),
                  const Divider(color: Colors.white24),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'Reports',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                      context, 'Analytics', Icons.analytics, 6, false),
                  _buildDrawerItem(
                      context, 'Exports', Icons.file_download, 7, false),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
    );
  }

  // Drawer item widget
  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    int index,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
      tileColor:
          isSelected ? Colors.white.withValues(alpha: 25) : Colors.transparent,
      onTap: () {
        if (index <= 2) {
          _tabController.animateTo(index);
          Navigator.pop(context);
        }
      },
    );
  }

  Widget buildDashboardTab(
    List<Map<String, dynamic>> dashboardItems,
    Size size,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
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
                        'Dashboard Overview',
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
                        'Total Users',
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
                        'Total Enquiries',
                        _totalEnquiries.toString(),
                        Icons.question_answer,
                        Colors.purpleAccent,
                        _isLoading,
                      ),
                      _buildStatCard(
                        'Pending Approvals',
                        _pendingApprovals.toString(),
                        Icons.pending_actions,
                        Colors.redAccent,
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
                final item = dashboardItems[index];
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
              childCount: dashboardItems.length,
            ),
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
                'Total Users',
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
                'Total Enquiries',
                _totalEnquiries.toString(),
                Icons.question_answer,
                Colors.purpleAccent,
                _isLoading,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Pending Approvals',
                _pendingApprovals.toString(),
                Icons.pending_actions,
                Colors.redAccent,
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
                color: color.withValues(alpha: 25),
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

  Widget buildStatisticsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics & Analytics',
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
                  color: Colors.black.withValues(alpha: 13),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Task Completion Rate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 2),
                            FlSpot(2, 5),
                            FlSpot(3, 4),
                            FlSpot(4, 6),
                            FlSpot(5, 3),
                            FlSpot(6, 7),
                          ],
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: _gradientColors
                                .map((color) => color.withValues(alpha: 76))
                                .toList(),
                          ),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: _gradientColors
                                  .map((color) => color.withValues(alpha: 76))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        if (index <= 2) {
          _tabController.animateTo(index);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 25)
              : Colors.transparent,
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
}
