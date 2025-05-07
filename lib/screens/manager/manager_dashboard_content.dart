// lib/screens/manager/manager_dashboard_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/screens/common/attendance_history_screen.dart';
import 'package:z_emp/screens/common/user_todo_task_list_screen.dart';
import 'package:z_emp/screens/sales_staff/enquiry_list_screen.dart';
import 'package:z_emp/screens/sales_staff/job_enquiry_screen.dart';
import 'package:z_emp/screens/sales_staff/sales_data_entry_screen.dart';
import 'package:z_emp/screens/sales_staff/sales_order_history_screen.dart';
import '../../widgets/profile_section.dart';
import '../../widgets/dashboard_tile.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/clock_in_out_button.dart';
import 'team_performance_screen.dart';
import 'task_approval_screen.dart';
import 'customer_task_data_screen.dart';
import '../common/leave_request_form.dart';
import '../../providers/announcement_provider.dart';
// NEW: Import the performance analytics card
import '../../widgets/performance_analytics_card.dart';

class ManagerDashboardContent extends StatefulWidget {
  const ManagerDashboardContent({super.key});

  @override
  State<ManagerDashboardContent> createState() => _ManagerDashboardContentState();
}

class _ManagerDashboardContentState extends State<ManagerDashboardContent> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> dashboardItems = [
    {
      'title': 'Team Performance',
      'icon': Icons.assessment,
      'color': Colors.deepPurple,
      'screen': const TeamPerformanceScreen(),
    },
    {
      'title': 'Task Approvals',
      'icon': Icons.check_circle,
      'color': Colors.indigo,
      'screen': const TaskApprovalScreen(),
    },
    {
      'title': 'To-do List',
      'icon': Icons.work_outline,
      'color': Colors.deepPurple,
      'screen': const UserTodoTaskListScreen(),
    },
    {
      'title': 'Job Enquiries',
      'icon': Icons.work_outline,
      'color': Colors.deepPurple,
      'screen': const JobEnquiryScreen(),
    },
    {
      'title': 'Enquiry List',
      'icon': Icons.follow_the_signs,
      'color': Colors.indigo,
      'screen': const EnquiryListScreen(),
    },
    {
      'title': 'Sales Data Entry',
      'icon': Icons.edit_note,
      'color': Colors.teal,
      'screen': const SalesDataEntryScreen(),
    },
    {
      'title': 'Enquiry History',
      'icon': Icons.storage_rounded,
      'color': Colors.brown,
      'screen': const SalesOrderHistoryScreen(),
    },
    {
      'title': 'Customer Task Data',
      'icon': Icons.data_usage,
      'color': Colors.orange,
      'screen': const CustomerTaskDataScreen(),
    },
    {
      'title': 'Leave Requests',
      'icon': Icons.time_to_leave,
      'color': Colors.green,
      'screen': const LeaveRequestForm(),
    },
    {
      'title': 'Attendance',
      'icon': Icons.access_time,
      'color': Colors.blueGrey,
      'screen': const AttendanceHistoryScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<AnnouncementProvider>(context, listen: false)
                .fetchAnnouncements();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSection(),
              const AnnouncementCard(role: "manager"),
              const ClockInOutButton(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Page 1: Grid of dashboard tiles
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: dashboardItems.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
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
                    // Page 2: Performance Analytics card
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      child: const PerformanceAnalyticsCard(),
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
}
