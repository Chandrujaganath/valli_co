// lib/widgets/performance_analytics_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sales_service.dart';
import '../services/enquiry_service.dart';
import '../services/todo_task_service.dart';
import '../providers/user_provider.dart';
import '../models/sales_model.dart';
import '../models/enquiry_model.dart';
import '../models/todo_task_model.dart';

/// Displays performance analytics for a single user (e.g., # of enquiries, # of sales, # of tasks).
class PerformanceAnalyticsCard extends StatefulWidget {
  const PerformanceAnalyticsCard({super.key});

  @override
  State<PerformanceAnalyticsCard> createState() => _PerformanceAnalyticsCardState();
}

class _PerformanceAnalyticsCardState extends State<PerformanceAnalyticsCard> {
  bool isLoading = true;

  // Sales
  int totalSales = 0;
  int completedSales = 0;

  // Enquiries
  int totalEnquiries = 0;
  int closedEnquiries = 0; // e.g., "Sale done" or "Completed" statuses

  // Tasks
  int totalTasks = 0;
  int completedTasks = 0;

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      setState(() => isLoading = false);
      return;
    }

    final salesService = Provider.of<SalesService>(context, listen: false);
    final enquiryService = Provider.of<EnquiryService>(context, listen: false);
    final todoTaskService = Provider.of<TodoTaskService>(context, listen: false);

    try {
      // 1) Sales Data
      List<SalesModel> userSales =
          await salesService.getSalesByUserId(currentUser.userId);
      totalSales = userSales.length;
      // Example: "Payment Done" to mark completed sale
      completedSales = userSales.where((sale) => sale.salesStatus == 'Payment Done').length;

      // 2) Enquiries
      List<EnquiryModel> userEnquiries =
          await enquiryService.getEnquiriesByUserId(currentUser.userId);
      totalEnquiries = userEnquiries.length;
      // Example: 'Sale done' or 'MOK' or 'MTBT'? Adjust as needed
      closedEnquiries = userEnquiries.where((enq) => enq.status == 'Sale done').length;

      // 3) Tasks
      // Using "getTasksByUserId" from your TodoTaskService
      List<TodoTaskModel> userTasks =
          await todoTaskService.getTasksByUserIdStreamOnce(currentUser.userId);
      // If your existing method returns a stream, you can create a new method that returns the tasks once
      totalTasks = userTasks.length;
      completedTasks = userTasks.where((task) => task.status == 'Completed').length;

    } catch (e) {
      debugPrint('Error fetching performance data: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        elevation: 4,
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 16),

            // Sales Row
            _buildStatRow(
              label: 'Sales',
              total: totalSales,
              completed: completedSales,
              completedLabel: 'Payment Done',
            ),

            // Enquiries Row
            _buildStatRow(
              label: 'Enquiries',
              total: totalEnquiries,
              completed: closedEnquiries,
              completedLabel: 'Closed',
            ),

            // Tasks Row
            _buildStatRow(
              label: 'Tasks',
              total: totalTasks,
              completed: completedTasks,
              completedLabel: 'Completed',
            ),

            const SizedBox(height: 16),
            // You could add small charts or visuals if needed
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required int total,
    required int completed,
    required String completedLabel,
  }) {
    int pending = total - completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $total', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '$completedLabel: $completed',
                style: const TextStyle(color: Colors.green),
              ),
            ),
            Expanded(
              child: Text(
                'Pending: $pending',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        const Divider(thickness: 1),
      ],
    );
  }
}
