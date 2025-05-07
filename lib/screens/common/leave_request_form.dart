// lib/screens/common/leave_request_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/leave_request_service.dart';
import '../../models/leave_request_model.dart';

class LeaveRequestForm extends StatefulWidget {
  const LeaveRequestForm({super.key});

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController reasonController = TextEditingController();
  String leaveType = 'Sick Leave';
  String dayType = 'Full Day';
  DateTime? startDate;
  DateTime? endDate;
  String? userName;

  late TabController _tabController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _tabController = TabController(length: 2, vsync: this);

    // Update dayType when switching tabs (0 => Full Day, 1 => Half Day)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          dayType = _tabController.index == 0 ? 'Full Day' : 'Half Day';
        });
      }
    });
  }

  @override
  void dispose() {
    reasonController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (!mounted) return;
        setState(() {
          userName = userDoc['name'] ?? 'User';
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          userName = 'User';
        });
      }
    }
  }

  /// Opens a date picker for either the start or end date.
  /// Allows any date from 2000 to 2101 (including past dates).
  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2101);

    // Use whichever date is currently selected if available; otherwise default to "now"
    final DateTime initialDate =
        isStart ? (startDate ?? now) : (endDate ?? now);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          startDate = pickedDate;
        } else {
          endDate = pickedDate;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to request leave.')),
      );
    }

    final leaveRequestService =
        Provider.of<LeaveRequestService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Container(
            // Use a gradient background
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTitle(),
                  const SizedBox(height: 24),
                  _buildLeaveDetailsCard(
                      context, currentUser.uid, leaveRequestService),
                  const SizedBox(height: 32),
                  _buildPreviousRequestsSection(
                      currentUser.uid, leaveRequestService),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Text(
      'Submit Leave Request',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade700,
      ),
    );
  }

  Widget _buildLeaveDetailsCard(
    BuildContext context,
    String userId,
    LeaveRequestService leaveRequestService,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Type
            const Text(
              'Leave Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: leaveType,
              items: const [
                DropdownMenuItem(
                    value: 'Sick Leave', child: Text('Sick Leave')),
                DropdownMenuItem(
                    value: 'Personal Leave', child: Text('Personal Leave')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => leaveType = value);
              },
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date Pickers Section
            if (dayType == 'Full Day')
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Start Date',
                      date: startDate,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      label: 'End Date',
                      date: endDate,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              )
            else
              _buildDateSelector(
                label: 'Date',
                date: startDate,
                onTap: () => _pickDate(isStart: true),
              ),

            const SizedBox(height: 24),

            // Reason
            const Text(
              'Reason for Leave',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter your reason here...',
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!await _validateAndSubmit(leaveRequestService, userId)) {
                    return;
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Leave request submitted successfully')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit Leave Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _validateAndSubmit(
      LeaveRequestService leaveRequestService, String userId) async {
    // Validate user input based on "Full Day" vs "Half Day"
    if (dayType == 'Full Day') {
      // Must have both dates
      if (startDate == null || endDate == null) {
        _showError('Please select both start and end dates.');
        return false;
      }
      // For a full-day leave, end date must be after the start date
      if (!endDate!.isAfter(startDate!)) {
        _showError(
            'End date must be later than start date for a full-day leave.');
        return false;
      }
    } else {
      // "Half Day" requires only a startDate
      if (startDate == null) {
        _showError('Please select a date for half-day leave.');
        return false;
      }
      // For consistency, let's set endDate to startDate, or you can let it remain null
      endDate = startDate;
    }

    // Reason required
    if (reasonController.text.trim().isEmpty) {
      _showError('Please provide a reason for leave.');
      return false;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await leaveRequestService.submitLeaveRequest(
        userId: userId,
        name: userName ?? 'User',
        leaveType: leaveType,
        startDate: Timestamp.fromDate(startDate!),
        endDate: Timestamp.fromDate(endDate!),
        dayType: dayType,
        reason: reasonController.text.trim(),
      );

      // Reset fields after successful submission
      setState(() {
        reasonController.clear();
        leaveType = 'Sick Leave';
        dayType = _tabController.index == 0 ? 'Full Day' : 'Half Day';
        startDate = null;
        endDate = null;
      });
      return true;
    } catch (e) {
      _showError('Failed to submit leave request: $e');
      return false;
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date == null ? label : _formatDate(date),
                style: TextStyle(
                  color: date == null ? Colors.grey.shade600 : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousRequestsSection(
      String userId, LeaveRequestService leaveRequestService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Previous Leave Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Icon(
              Icons.history,
              color: Colors.deepPurple.shade400,
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<LeaveRequestModel>>(
          stream: leaveRequestService.getUserLeaveRequests(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text('Error loading previous leave requests.');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No previous leave requests.');
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!
                    .map((leave) => _buildLeaveRequestCard(leave))
                    .toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequestModel leave) {
    final start = DateFormat('yyyy-MM-dd').format(leave.startDate.toDate());
    final end = DateFormat('yyyy-MM-dd').format(leave.endDate.toDate());

    // Determine color by status
    final String statusText = leave.status.toLowerCase();
    Color statusColor;
    if (statusText == 'approved') {
      statusColor = Colors.green;
    } else if (statusText == 'rejected') {
      statusColor = Colors.red;
    } else {
      // e.g. pending or other statuses
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // A vertical colored bar on the left
          Container(
            width: 6,
            height: 100, // or double.infinity if you'd like it taller
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              title: Text(
                'User: ${leave.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  'Leave Type: ${leave.leaveType} (${leave.dayType})\n'
                  'From: $start to $end\n'
                  'Status: ${leave.status}\n'
                  'Reason: ${leave.reason}\n'
                  'Approved By: ${leave.approvedBy ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
