// lib/screens/sales_staff/sales_records_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/sales_service.dart';
import '../../providers/user_provider.dart';
import '../../models/sales_model.dart';

class SalesRecordsScreen extends StatefulWidget {
  const SalesRecordsScreen({super.key});

  @override
  State<SalesRecordsScreen> createState() => _SalesRecordsScreenState();
}

class _SalesRecordsScreenState extends State<SalesRecordsScreen> {
  bool _isLoading = false;
  List<SalesModel> _salesList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserSales();
  }

  Future<void> _fetchUserSales() async {
    setState(() => _isLoading = true);

    try {
      final salesService = Provider.of<SalesService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final currentUser = userProvider.user;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      // Fetch the user's sales from Firestore
      final userSales = await salesService.getSalesByUserId(currentUser.userId);
      setState(() => _salesList = userSales);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching sales: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchUserSales();
  }

  // Display a detail popup for the tapped sale record.
  void _showSaleDetailDialog(SalesModel sale) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sale Detail (CR: ${sale.crNumbers})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Customer', sale.customerName),
                _buildDetailRow('Sales Date',
                    DateFormat('yyyy-MM-dd').format(sale.salesDate)),
                _buildDetailRow('Total Cash Sales', '${sale.totalCashSales}'),
                _buildDetailRow('CR Amount', '${sale.crAmount}'),
                _buildDetailRow('Number of Cash Sales',
                    '${sale.numberOfCashSales}'),
                _buildDetailRow('Product Category', sale.productCategory),
                _buildDetailRow(
                    'TAT Date', DateFormat('yyyy-MM-dd').format(sale.tatDate)),
                // Show notes if available
                if (sale.additionalNotes != null &&
                    sale.additionalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Notes', sale.additionalNotes!),
                ],
                // You can add more fields here if needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to format each field consistently
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Records'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _salesList.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No sales records found.'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _salesList.length,
                      itemBuilder: (context, index) {
                        final sale = _salesList[index];
                        return _buildSaleCard(sale);
                      },
                    ),
            ),
    );
  }

  Widget _buildSaleCard(SalesModel sale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSaleDetailDialog(sale),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CR Numbers as Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CR: ${sale.crNumbers}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    // Show sales date in short format
                    DateFormat('dd MMM yyyy').format(sale.salesDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Customer Name
              Text(
                sale.customerName,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              // Total Cash Sales
              Text(
                'Total Sales: ${sale.totalCashSales}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              // If you want to highlight product category
              Text(
                'Category: ${sale.productCategory}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              // Additional notes snippet if any
              if (sale.additionalNotes != null &&
                  sale.additionalNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Notes: ${sale.additionalNotes}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
