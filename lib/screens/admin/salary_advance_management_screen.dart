// lib/screens/admin/salary_advance_management_screen.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/salary_advance_model.dart';
import '../../services/salary_advance_service.dart';
import '../../providers/user_provider.dart';

class SalaryAdvanceManagementScreen extends StatefulWidget {
  const SalaryAdvanceManagementScreen({super.key});

  @override
  _SalaryAdvanceManagementScreenState createState() =>
      _SalaryAdvanceManagementScreenState();
}

class _SalaryAdvanceManagementScreenState
    extends State<SalaryAdvanceManagementScreen> {
  /// Holds all requests from Firestore.
  List<SalaryAdvanceModel> _allRequests = [];

  /// Holds only requests after applying search & sort filters.
  List<SalaryAdvanceModel> _filteredRequests = [];

  /// For controlling loading states.
  bool _isLoading = true;

  /// Search and sort state.
  String _searchQuery = '';
  String _sortBy = 'Date Submitted';
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
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
      return request.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Sort the filtered list
    Comparator<SalaryAdvanceModel> comparator;
    if (_sortBy == 'Date Submitted') {
      comparator = (a, b) => a.dateSubmitted.compareTo(b.dateSubmitted);
    } else if (_sortBy == 'Amount') {
      comparator = (a, b) => a.amountRequested.compareTo(b.amountRequested);
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
      appBar: AppBar(
        title: const Text('Salary Advance Management'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(adminUser.name),
    );
  }

  Widget _buildMainContent(String adminName) {
    // Separate Pending and Processed from _filteredRequests
    List<SalaryAdvanceModel> pendingRequests =
        _filteredRequests.where((req) => req.status == 'Pending').toList();
    List<SalaryAdvanceModel> processedRequests =
        _filteredRequests.where((req) => req.status != 'Pending').toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Pending Requests
            if (pendingRequests.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index];
                      return _buildRequestCard(
                        request: request,
                        adminName: adminName,
                      );
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Search & Sort
            _buildSearchAndSortOptions(),
            const SizedBox(height: 16),

            // Approved/Rejected
            if (processedRequests.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Approved/Rejected Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: processedRequests.length,
                    itemBuilder: (context, index) {
                      final request = processedRequests[index];
                      return _buildProcessedRequestCard(request);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSortOptions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search Field
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value.trim();
                _applySortingAndFiltering();
              },
            ),
            const SizedBox(height: 12),
            // Sort Options
            Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  items: ['Date Submitted', 'Amount'].map((String value) {
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
                ),
                IconButton(
                  icon: Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
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
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard({
    required SalaryAdvanceModel request,
    required String adminName,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(
          '₹${request.amountRequested.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Requested by: ${request.name}'),
        trailing: const Icon(Icons.more_vert),
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Reason'),
            subtitle: Text(request.reason),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Repayment Option'),
            subtitle: Text(request.repaymentOption),
          ),
          if (request.repaymentOption == 'Single Payment')
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Repayment Month'),
              subtitle: Text(request.repaymentMonth ?? ''),
            ),
          if (request.repaymentOption == 'Part Payment')
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Repayment Period'),
              subtitle: Text(
                '${request.repaymentFromMonth} to ${request.repaymentToMonth}',
              ),
            ),
          if (request.attachmentUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attachment'),
              subtitle: TextButton(
                onPressed: () => _launchURL(request.attachmentUrl),
                child: const Text('Download/View Attachment'),
              ),
            ),
          _buildActionButtons(request, adminName),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    SalaryAdvanceModel request,
    String adminName,
  ) {
    final salaryAdvanceService =
        Provider.of<SalaryAdvanceService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () async {
              await _confirmAction(context, 'Approve', () async {
                await salaryAdvanceService.updateSalaryAdvanceStatus(
                  request.advanceId,
                  'Approved',
                  approvedBy: adminName,
                );
                // Refresh local data
                await _loadRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request Approved')),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Approve'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              await _confirmAction(context, 'Reject', () async {
                await salaryAdvanceService.updateSalaryAdvanceStatus(
                  request.advanceId,
                  'Rejected',
                  approvedBy: adminName,
                );
                // Refresh local data
                await _loadRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request Rejected')),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedRequestCard(SalaryAdvanceModel request) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(
          '₹${request.amountRequested.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Requested by: ${request.name}'),
        trailing: Icon(
          Icons.circle,
          color: _getStatusColor(request.status),
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Reason'),
            subtitle: Text(request.reason),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Repayment Option'),
            subtitle: Text(request.repaymentOption),
          ),
          if (request.repaymentOption == 'Single Payment')
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Repayment Month'),
              subtitle: Text(request.repaymentMonth ?? ''),
            ),
          if (request.repaymentOption == 'Part Payment')
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Repayment Period'),
              subtitle:
                  Text('${request.repaymentFromMonth} to ${request.repaymentToMonth}'),
            ),
          if (request.attachmentUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attachment'),
              subtitle: TextButton(
                onPressed: () => _launchURL(request.attachmentUrl),
                child: const Text('Download/View Attachment'),
              ),
            ),
          ListTile(
            leading: Icon(
              Icons.info,
              color: _getStatusColor(request.status),
            ),
            title: Text(
              'Status: ${request.status}',
              style: TextStyle(
                color: _getStatusColor(request.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Processed by: ${request.approvedBy}\n'
              'on ${request.approvalDate?.toDate().toLocal().toString().split(' ')[0] ?? 'N/A'}',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.blue;
    }
  }

  Future<void> _confirmAction(
    BuildContext context,
    String action,
    Future<void> Function() onConfirm,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Request'),
        content: Text('Are you sure you want to $action this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onConfirm();
    }
  }
}
