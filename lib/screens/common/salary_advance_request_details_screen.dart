// lib/screens/salary_advance_request_details_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:z_emp/models/salary_advance_model.dart';
import 'package:url_launcher/url_launcher.dart'; // To handle attachment viewing

class SalaryAdvanceRequestDetailsScreen extends StatelessWidget {
  final SalaryAdvanceModel request;

  const SalaryAdvanceRequestDetailsScreen({super.key, required this.request});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildRequestDetails(context),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context) {
    return ListView(
      children: [
        _buildDetailTile(
          title: 'Amount Requested',
          value: '₹${request.amountRequested.toStringAsFixed(2)}',
          icon: Icons.monetization_on,
        ),
        _buildDetailTile(
          title: 'Reason',
          value: request.reason,
          icon: Icons.comment,
        ),
        _buildDetailTile(
          title: 'Repayment Option',
          value: request.repaymentOption,
          icon: Icons.receipt,
        ),
        if (request.repaymentOption == 'Single Payment')
          _buildDetailTile(
            title: 'Repayment Month',
            value: request.repaymentMonth ?? '',
            icon: Icons.calendar_month,
          ),
        if (request.repaymentOption == 'Part Payment')
          _buildDetailTile(
            title: 'Repayment Period',
            value: '${request.repaymentFromMonth} to ${request.repaymentToMonth}',
            icon: Icons.date_range,
          ),
        _buildDetailTile(
          title: 'Date Submitted',
          value: request.dateSubmitted
              .toDate()
              .toLocal()
              .toString()
              .split(' ')[0],
          icon: Icons.today,
        ),
        if (request.attachmentUrl.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Attachment'),
            subtitle: TextButton(
              onPressed: () => _launchURL(context, request.attachmentUrl),
              child: const Text('Download/View Attachment'),
            ),
          ),
        if (request.status != 'Pending')
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
              'Processed By: ${request.approvedBy}\non ${request.approvalDate?.toDate().toLocal().toString().split(' ')[0]}',
            ),
          ),
      ],
    );
  }

  Widget _buildDetailTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      subtitle: Text(value),
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
}
