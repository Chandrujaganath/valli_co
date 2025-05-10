// lib/screens/salary_advance_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:valli_and_co/models/salary_advance_model.dart';
import 'package:valli_and_co/providers/user_provider.dart';
import 'package:valli_and_co/services/salary_advance_service.dart';
import 'package:valli_and_co/screens/common/salary_advance_request_details_screen.dart';
import 'package:valli_and_co/utils/app_colors.dart';
import 'salary_advance_form.dart';

class SalaryAdvanceScreen extends StatefulWidget {
  const SalaryAdvanceScreen({super.key});

  @override
  State<SalaryAdvanceScreen> createState() => _SalaryAdvanceScreenState();
}

class _SalaryAdvanceScreenState extends State<SalaryAdvanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<SalaryAdvanceModel> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final salaryAdvanceService =
          Provider.of<SalaryAdvanceService>(context, listen: false);
      final requests =
          await salaryAdvanceService.getUserSalaryAdvances(currentUser.userId);

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: 150.0,
                    pinned: true,
                    floating: true,
                    backgroundColor: AppColors.indigo,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: const Text('Salary Advance'),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.indigo.withOpacity(0.7),
                              AppColors.indigo,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 0, 20.0, 70.0),
                          child: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  'Hello, ${currentUser.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: Container(
                        color: AppColors.indigo,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Pending'),
                            Tab(text: 'Completed'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                body: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsList(context, _requests),
                          _buildRequestsList(
                            context,
                            _requests
                                .where((req) => req.status == 'Pending')
                                .toList(),
                          ),
                          _buildRequestsList(
                            context,
                            _requests
                                .where((req) => req.status != 'Pending')
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalaryAdvanceForm(),
            ),
          );
          _loadRequests(); // Refresh list after returning from form
        },
        backgroundColor: AppColors.accent,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Request Advance'),
      ),
    );
  }

  Widget _buildRequestsList(
      BuildContext context, List<SalaryAdvanceModel> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No requests found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(context, request);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, SalaryAdvanceModel request) {
    final dateSubmitted = DateFormat('MMM dd, yyyy')
        .format(request.dateSubmitted.toDate().toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getBorderColor(request.status),
          width: 1.5,
        ),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SalaryAdvanceRequestDetailsScreen(request: request),
            ),
          ).then((_) => _loadRequests()); // Refresh after viewing details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${request.amountRequested.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Reason: ${request.reason}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateSubmitted,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (request.attachmentUrl.isNotEmpty)
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Colors.grey,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;

    switch (status) {
      case 'Approved':
        backgroundColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'Rejected':
        backgroundColor = Colors.red;
        iconData = Icons.cancel;
        break;
      case 'Pending':
      default:
        backgroundColor = Colors.orange;
        iconData = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade200;
      case 'Rejected':
        return Colors.red.shade200;
      case 'Pending':
      default:
        return Colors.orange.shade200;
    }
  }
}
