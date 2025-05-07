// lib/screens/sales_staff/sale_history_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaleHistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> historyDoc;

  const SaleHistoryDetailScreen({
    super.key,
    required this.historyDoc,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = historyDoc['customerName'] ?? 'Unknown';
    final phone = historyDoc['phoneNumber'] ?? '';
    final productCategory = historyDoc['productCategory'] ?? '';
    final createdAtTs = historyDoc['createdAt'] as Timestamp?;
    final createdAt = createdAtTs?.toDate();
    final dateStr =
        createdAt != null ? DateFormat('yyyy-MM-dd').format(createdAt) : '--';
    final currentStatus = historyDoc['currentStatus'] ?? 'N/A';
    final List statusHistory = historyDoc['statusHistory'] ?? [];

    // Additional fields
    final orderValue = historyDoc['orderValue'];
    final crNumber = historyDoc['crNumber'];
    final tatDateTs = historyDoc['tatDate'] as Timestamp?;
    final tatDateStr = tatDateTs != null
        ? DateFormat('yyyy-MM-dd').format(tatDateTs.toDate())
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale History Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Details
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Phone: $phone', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Product: $productCategory',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Created: $dateStr',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Text(
                      'Current Status: $currentStatus',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Details (if present)
                    if (orderValue != null ||
                        crNumber != null ||
                        tatDateStr != null) ...[
                      const Text(
                        'Additional Details:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (orderValue != null)
                        ListTile(
                          leading: const Icon(Icons.monetization_on,
                              color: Colors.orange),
                          title: Text('Order Value: $orderValue'),
                        ),
                      if (crNumber != null)
                        ListTile(
                          leading: const Icon(Icons.confirmation_number,
                              color: Colors.deepPurple),
                          title: Text('CR Number: $crNumber'),
                        ),
                      if (tatDateStr != null)
                        ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.teal),
                          title: Text('Tat Date: $tatDateStr'),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Status History
                    const Text(
                      'Status History:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    if (statusHistory.isEmpty)
                      const Text('No status updates recorded.'),
                    if (statusHistory.isNotEmpty)
                      ...statusHistory.map((entry) {
                        final status = entry['status'] ?? '';
                        final updatedAtTs = entry['updatedAt'] as Timestamp?;
                        final updatedAt = updatedAtTs?.toDate();
                        final updatedAtStr = updatedAt != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(updatedAt)
                            : '--';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            title: Text(status),
                            subtitle: Text('Updated: $updatedAtStr'),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
