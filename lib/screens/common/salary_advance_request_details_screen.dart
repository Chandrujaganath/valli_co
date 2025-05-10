// lib/screens/salary_advance_request_details_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:valli_and_co/models/salary_advance_model.dart';
import 'package:valli_and_co/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SalaryAdvanceRequestDetailsScreen extends StatelessWidget {
  final SalaryAdvanceModel request;

  const SalaryAdvanceRequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: AppColors.indigo,
        elevation: 0,
        actions: [
          if (request.attachmentUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.attachment),
              onPressed: () => _launchURL(context, request.attachmentUrl),
              tooltip: 'View Attachment',
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Request Timeline',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTimeline(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Request Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDetailsCard(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.indigo,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount Requested',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${request.amountRequested.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(request.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final dateSubmitted = DateFormat('MMM dd, yyyy').format(
      request.dateSubmitted.toDate().toLocal(),
    );

    String? processedDate;
    if (request.approvalDate != null) {
      processedDate = DateFormat('MMM dd, yyyy').format(
        request.approvalDate!.toDate().toLocal(),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTimelineColumn(context, request.status),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineItem(
                  title: 'Request Submitted',
                  subtitle: dateSubmitted,
                  isActive: true,
                ),
                const SizedBox(height: 30),
                _buildTimelineItem(
                  title: 'Under Review',
                  subtitle: request.status == 'Pending'
                      ? 'Your request is being reviewed'
                      : 'Completed',
                  isActive: true,
                ),
                const SizedBox(height: 30),
                _buildTimelineItem(
                  title: request.status == 'Approved'
                      ? 'Request Approved'
                      : request.status == 'Rejected'
                          ? 'Request Rejected'
                          : 'Approval Pending',
                  subtitle: request.status != 'Pending'
                      ? 'By ${request.approvedBy} on $processedDate'
                      : 'Awaiting decision',
                  isActive: request.status != 'Pending',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineColumn(BuildContext context, String status) {
    final int completedSteps = status == 'Pending' ? 2 : 3;

    return Column(
      children: [
        _buildTimelineDot(isActive: true),
        _buildTimelineConnector(isActive: true),
        _buildTimelineDot(isActive: true),
        _buildTimelineConnector(isActive: completedSteps > 2),
        _buildTimelineDot(isActive: completedSteps > 2),
      ],
    );
  }

  Widget _buildTimelineDot({required bool isActive}) {
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        color: isActive ? AppColors.indigo : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.indigo : Colors.grey.shade300,
          width: 3,
        ),
      ),
    );
  }

  Widget _buildTimelineConnector({required bool isActive}) {
    return Container(
      width: 2,
      height: 50,
      color: isActive ? AppColors.indigo : Colors.grey.shade300,
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? Colors.black54 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context: context,
              icon: Icons.description,
              title: 'Reason',
              value: request.reason,
            ),
            const Divider(),
            _buildDetailRow(
              context: context,
              icon: Icons.payment,
              title: 'Repayment Option',
              value: request.repaymentOption,
            ),
            const Divider(),
            if (request.repaymentOption == 'Single Payment')
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month,
                title: 'Repayment Month',
                value: request.repaymentMonth ?? 'Not specified',
              )
            else if (request.repaymentOption == 'Part Payment')
              _buildDetailRow(
                context: context,
                icon: Icons.date_range,
                title: 'Repayment Period',
                value:
                    '${request.repaymentFromMonth} to ${request.repaymentToMonth}',
              ),
            if (request.repaymentOption == 'Part Payment') const Divider(),
            if (request.status != 'Pending')
              _buildDetailRow(
                context: context,
                icon: Icons.person,
                title: 'Processed By',
                value: request.approvedBy,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.indigo,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
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
}
