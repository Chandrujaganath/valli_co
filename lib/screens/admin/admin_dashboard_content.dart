// lib/screens/admin/admin_dashboard_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/screens/admin/admin_todo_task_history_screen.dart';
import 'package:z_emp/widgets/overview_card.dart';
import 'admin_todo_task_assignment_screen.dart';
import 'admin_todo_task_list_screen.dart';
import 'announcement_management_screen.dart';
import 'user_management_screen.dart';
import 'enquiry_management_screen.dart';
import 'leave_management_screen.dart';
import 'salary_advance_management_screen.dart';
import 'attendance_overview_screen.dart';
import 'report_generation_screen.dart';
import 'organisation_management_screen.dart';
import 'product_management_screen.dart';
import 'product_list_screen.dart';
import 'geo_fence_management_screen.dart';
import '../common/customer_details_screen.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/profile_section.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/dashboard_tile.dart';

// Import localization
import '../../l10n/app_localizations.dart';

class AdminDashboardContent extends StatefulWidget {
  const AdminDashboardContent({super.key});

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  final PageController _pageController = PageController();

  /// We'll store the 'titleKey' for each item, so we can translate inside build().
  final List<Map<String, dynamic>> _dashboardItemsData = [
    {
      'titleKey': 'to_do',
      'icon': Icons.task_rounded,
      'color': Colors.indigo,
      'screen': const AdminTodoTaskAssignmentScreen(),
    },
    {
      'titleKey': 'to_do_list',
      'icon': Icons.task_alt,
      'color': Colors.indigo,
      'screen': const AdminTodoTaskListScreen(),
    },
    {
      'titleKey': 'to_do_history',
      'icon': Icons.history,
      'color': Colors.indigo,
      'screen': const AdminTodoTaskHistoryScreen(),
    },
    {
      'titleKey': 'enquiries',
      'icon': Icons.question_answer,
      'color': Colors.purple,
      'screen': const EnquiryManagementScreen(),
    },
    {
      'titleKey': 'leave_requests',
      'icon': Icons.beach_access,
      'color': Colors.orange,
      'screen': const LeaveManagementScreen(),
    },
    {
      'titleKey': 'salary_advances',
      'icon': Icons.attach_money,
      'color': Colors.green,
      'screen': const SalaryAdvanceManagementScreen(),
    },
    {
      'titleKey': 'attendance',
      'icon': Icons.access_time,
      'color': Colors.blueGrey,
      'screen': const AttendanceOverviewScreen(),
    },
    {
      'titleKey': 'geo_fence',
      'icon': Icons.my_location,
      'color': Colors.lightBlue,
      'screen': const GeoFenceManagementScreen(),
    },
    {
      'titleKey': 'announcements',
      'icon': Icons.announcement,
      'color': Colors.amber,
      'screen': const AnnouncementManagementScreen(),
    },
    {
      'titleKey': 'reports',
      'icon': Icons.insert_drive_file,
      'color': Colors.brown,
      'screen': const ReportGenerationScreen(),
    },
    {
      'titleKey': 'manage_products',
      'icon': Icons.shopping_cart,
      'color': Colors.pinkAccent,
      'screen': const ProductManagementScreen(),
    },
    {
      'titleKey': 'products',
      'icon': Icons.store,
      'color': Colors.cyan,
      'screen': const ProductListScreen(),
    },
    {
      'titleKey': 'users',
      'icon': Icons.people,
      'color': Colors.deepPurple,
      'screen': const UserManagementScreen(),
    },
    {
      'titleKey': 'manage_branch',
      'icon': Icons.business,
      'color': Colors.deepOrange,
      'screen': const OrganisationManagementScreen(),
    },
    {
      'titleKey': 'customers_list',
      'icon': Icons.list_alt,
      'color': Colors.blueGrey,
      'screen': const CustomerListScreen(),
    },
  ];

  Future<void> _handleRefresh() async {
    await Provider.of<AnnouncementProvider>(context, listen: false)
        .fetchAnnouncements();
    // Add other refresh logic if needed.
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context);

    // Map the _dashboardItemsData to final items with translated titles
    final dashboardItems = _dashboardItemsData.map((item) {
      final titleKey = item['titleKey'] as String;
      return {
        'title': appLocalization?.translate(titleKey) ?? item['titleKey'],
        'icon': item['icon'],
        'color': item['color'],
        'screen': item['screen'],
      };
    }).toList();

    return Scaffold(
      body: Container(
        // Gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color.fromARGB(255, 49, 108, 196),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileSection(),
            const AnnouncementCard(role: "admin"),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // Page 1: Dashboard Tiles
                  RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        itemCount: dashboardItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = dashboardItems[index];
                          return DashboardTile(
                            title: item['title'],
                            icon: item['icon'],
                            color: item['color'],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => item['screen']),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Page 2: Overview Card
                  RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: const OverviewCard(),
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
