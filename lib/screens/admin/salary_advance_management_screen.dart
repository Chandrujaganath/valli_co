// lib/screens/admin/salary_advance_management_screen.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../models/salary_advance_model.dart';
import '../../services/salary_advance_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_colors.dart';

class SalaryAdvanceManagementScreen extends StatefulWidget {
  const SalaryAdvanceManagementScreen({super.key});

  @override
  _SalaryAdvanceManagementScreenState createState() =>
      _SalaryAdvanceManagementScreenState();
}

class _SalaryAdvanceManagementScreenState
    extends State<SalaryAdvanceManagementScreen>
    with SingleTickerProviderStateMixin {
  /// Holds all requests from Firestore.
  List<SalaryAdvanceModel> _allRequests = [];

  /// Holds only requests after applying search & sort filters.
  List<SalaryAdvanceModel> _filteredRequests = [];

  /// For controlling loading states.
  bool _isLoading = true;

  /// Tab controller for managing tabs
  late TabController _tabController;

  /// Search and sort state.
  String _searchQuery = '';
  String _sortBy = 'Date Submitted';
  bool _isAscending = false;

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

  /// Fetch all salary advances once.
  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      final salaryAdvanceService =
          Provider.of<SalaryAdvanceService>(context, listen: false);
      final allData = await salaryAdvanceService.getSalaryAdvances();

      setState(() {
        _allRequests = allData;
      });
      _applySortingAndFiltering();
    } catch (e) {
      print('Error loading salary advances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Applies current search query and sort option to `_allRequests`
  /// and updates `_filteredRequests`.
  void _applySortingAndFiltering() {
    // 1. Filter by search query
    List<SalaryAdvanceModel> tempList = _allRequests.where((request) {
      return request.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Sort the filtered list
    Comparator<SalaryAdvanceModel> comparator;
    if (_sortBy == 'Date Submitted') {
      comparator = (a, b) => a.dateSubmitted.compareTo(b.dateSubmitted);
    } else if (_sortBy == 'Amount') {
      comparator = (a, b) => a.amountRequested.compareTo(b.amountRequested);
    } else if (_sortBy == 'Name') {
      comparator = (a, b) => a.name.compareTo(b.name);
    } else {
      comparator = (a, b) => 0;
    }

    tempList.sort(comparator);
    if (!_isAscending) {
      tempList = tempList.reversed.toList();
    }

    setState(() {
      _filteredRequests = tempList;
    });
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);

      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment')),
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adminUser = userProvider.user;

    if (adminUser == null) {
      return const Center(child: Text('Admin not logged in.'));
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.indigo,
            flexibleSpace: FlexibleSpaceBar(
              title: const Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: Text('Salary Advance Management'),
              ),
              background: _buildDashboardHeader(),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
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
                    Tab(text: 'Pending'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Rejected'),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: _buildSearchAndSortOptions(),
              ),
            ),
            pinned: true,
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadRequests,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsList(_getPendingRequests(), adminUser.name),
                    _buildRequestsList(_getApprovedRequests(), adminUser.name),
                    _buildRequestsList(_getRejectedRequests(), adminUser.name),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 70.0),
          child: const SizedBox(height: 50), // Empty space placeholder
        ),
      ),
    );
  }

  Widget _buildSearchAndSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        TextField(
          decoration: InputDecoration(
            labelText: 'Search by Employee Name',
            hintText: 'Enter employee name',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.indigo, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onChanged: (value) {
            _searchQuery = value.trim();
            _applySortingAndFiltering();
          },
        ),
        const SizedBox(height: 12),
        // Sort Options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _sortBy,
                items: ['Date Submitted', 'Amount', 'Name'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                    _applySortingAndFiltering();
                  });
                },
                underline: Container(
                  height: 2,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.indigo,
                ),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                    _applySortingAndFiltering();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<SalaryAdvanceModel> _getPendingRequests() {
    return _filteredRequests.where((req) => req.status == 'Pending').toList();
  }

  List<SalaryAdvanceModel> _getApprovedRequests() {
    return _filteredRequests.where((req) => req.status == 'Approved').toList();
  }

  List<SalaryAdvanceModel> _getRejectedRequests() {
    return _filteredRequests.where((req) => req.status == 'Rejected').toList();
  }

  Widget _buildRequestsList(
      List<SalaryAdvanceModel> requests, String adminName) {
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
        return _buildRequestCard(request, adminName);
      },
    );
  }

  Widget _buildRequestCard(SalaryAdvanceModel request, String adminName) {
    final dateSubmitted = DateFormat('MMM dd, yyyy')
        .format(request.dateSubmitted.toDate().toLocal());
    final isPending = request.status == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(request.status).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
          child: Text(
            request.name.isNotEmpty ? request.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: _getStatusColor(request.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  request.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${NumberFormat.compact().format(request.amountRequested)}',
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                dateSubmitted,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              if (request.attachmentUrl.isNotEmpty)
                Icon(
                  Icons.attach_file,
                  size: 12,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
        trailing: request.status == 'Pending'
            ? const Icon(Icons.more_vert)
            : _getStatusIcon(request.status),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Reason'),
                  subtitle: Text(request.reason),
                  dense: true,
                ),
                ListTile(
                  title: const Text('Repayment Option'),
                  subtitle: Text(request.repaymentOption),
                  dense: true,
                ),
                if (request.repaymentOption == 'Single Payment')
                  ListTile(
                    title: const Text('Repayment Month'),
                    subtitle: Text(request.repaymentMonth ?? ''),
                    dense: true,
                  ),
                if (request.repaymentOption == 'Part Payment')
                  ListTile(
                    title: const Text('Repayment Period'),
                    subtitle: Text(
                      '${request.repaymentFromMonth} to ${request.repaymentToMonth}',
                    ),
                    dense: true,
                  ),
                if (request.attachmentUrl.isNotEmpty)
                  ListTile(
                    title: const Text('Attachment'),
                    subtitle: GestureDetector(
                      onTap: () => _launchURL(request.attachmentUrl),
                      child: Text(
                        'View Attachment',
                        style: TextStyle(
                          color: AppColors.indigo,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    dense: true,
                  ),
                if (!isPending)
                  ListTile(
                    title: const Text('Processed By'),
                    subtitle: Text(
                      '${request.approvedBy} on ${request.approvalDate?.toDate().toLocal().toString().split(' ')[0]}',
                    ),
                    dense: true,
                  ),
                if (isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12.0,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _confirmAction(
                            context,
                            'Reject',
                            adminUser: adminName,
                            request: request,
                            status: 'Rejected',
                          ),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _confirmAction(
                            context,
                            'Approve',
                            adminUser: adminName,
                            request: request,
                            status: 'Approved',
                          ),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icon(Icons.check_circle, color: _getStatusColor(status));
      case 'Rejected':
        return Icon(Icons.cancel, color: _getStatusColor(status));
      case 'Pending':
      default:
        return Icon(Icons.hourglass_empty, color: _getStatusColor(status));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  Future<void> _confirmAction(
    BuildContext context,
    String action, {
    required String adminUser,
    required SalaryAdvanceModel request,
    required String status,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $action this request?'),
            const SizedBox(height: 12),
            Text('Employee: ${request.name}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Amount: ₹${request.amountRequested.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
            ),
            child: Text(action),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (confirmed == true) {
      final salaryAdvanceService =
          Provider.of<SalaryAdvanceService>(context, listen: false);

      await salaryAdvanceService.updateSalaryAdvanceStatus(
        request.advanceId,
        status,
        approvedBy: adminUser,
      );

      // Refresh local data
      await _loadRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Request ${status == 'Approved' ? 'Approved' : 'Rejected'}'),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 140; // Increased to accommodate the content

  @override
  double get minExtent => 140; // Increased to match maxExtent

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
