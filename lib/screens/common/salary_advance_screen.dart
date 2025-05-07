// lib/screens/salary_advance_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/models/salary_advance_model.dart';
import 'package:z_emp/providers/user_provider.dart';
import 'package:z_emp/services/salary_advance_service.dart';
import 'package:z_emp/screens/common/salary_advance_request_details_screen.dart';
import 'salary_advance_form.dart';

class SalaryAdvanceScreen extends StatelessWidget {
  const SalaryAdvanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Advance'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Request Advance Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalaryAdvanceForm(),
                  ),
                );
              },
              icon: const Icon(Icons.request_page),
              label: const Text(
                'Request Advance',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          // User's Request History
          Expanded(
            child: _buildUserRequestsList(context, currentUser.userId),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRequestsList(BuildContext context, String userId) {
    final salaryAdvanceService =
        Provider.of<SalaryAdvanceService>(context, listen: false);

    return FutureBuilder<List<SalaryAdvanceModel>>(
      future: salaryAdvanceService.getUserSalaryAdvances(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching requests.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No salary advance requests found.'));
        } else {
          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.indigo),
                  title: Text(
                    'Amount: ₹${request.amountRequested.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Status: ${request.status}'),
                  trailing: _statusIcon(request.status),
                  onTap: () {
                    // Navigate to request details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SalaryAdvanceRequestDetailsScreen(request: request),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _statusIcon(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      case 'Pending':
      default:
        color = Colors.blue;
        break;
    }
    return Icon(Icons.circle, color: color);
  }
}
