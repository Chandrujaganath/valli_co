// lib/screens/sales_staff/sales_order_history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sales_history_service.dart';
import 'sale_history_detail_screen.dart';

class SalesOrderHistoryScreen extends StatefulWidget {
  const SalesOrderHistoryScreen({super.key});

  @override
  _SalesOrderHistoryScreenState createState() => _SalesOrderHistoryScreenState();
}

class _SalesOrderHistoryScreenState extends State<SalesOrderHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _items = [];
  String _searchQuery = '';
  String _sortBy = 'createdAt'; // Default sort field.
  bool _descending = true;

  // New status filter.
  String _statusFilter = 'All';
  final List<String> _statusOptions = [
    'All',
    'Received all products',
    'Stitching Done',
    'Installation Done',
    'Payment Done'
  ];

  // The sequential status flow.
  final List<String> _statusFlow = [
    'Received all products',
    'Stitching Done',
    'Installation Done',
    'Payment Done',
  ];

  final SalesHistoryService _salesHistoryService = SalesHistoryService();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final docs = await _salesHistoryService.getSalesHistory(
        sortBy: _sortBy,
        descending: _descending,
        searchQuery: _searchQuery,
      );
      // Apply status filter if not "All".
      List<Map<String, dynamic>> filteredDocs = docs;
      if (_statusFilter != 'All') {
        filteredDocs = docs.where((doc) => doc['currentStatus'] == _statusFilter).toList();
      }
      setState(() {
        _items = filteredDocs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching history: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get the next status based on the current status.
  String? _getNextStatus(String current) {
    final idx = _statusFlow.indexOf(current);
    if (idx == -1 || idx >= _statusFlow.length - 1) return null;
    return _statusFlow[idx + 1];
  }

  Future<void> _updateStatus(Map<String, dynamic> doc) async {
    final docId = doc['docId'] as String;
    final currentStatus = doc['currentStatus'] as String? ?? '';
    final nextStatus = _getNextStatus(currentStatus);
    if (nextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No further status updates available.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Update status from "$currentStatus" to "$nextStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          )
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _salesHistoryService.updateSaleHistoryStatus(docId, nextStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $nextStatus.')),
      );
      _fetchHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  // Build filter & sort options container.
  Widget _buildFilterSortOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter by Status.
          Row(
            children: [
              const Text(
                'Filter by Status: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _statusFilter,
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statusFilter = value;
                    });
                    _fetchHistory();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sorting Options.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Sort by: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(
                        value: 'customerName',
                        child: Text('Customer'),
                      ),
                      DropdownMenuItem(
                        value: 'createdAt',
                        child: Text('Date'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                        _fetchHistory();
                      }
                    },
                  ),
                ],
              ),
              IconButton(
                icon: Icon(_descending ? Icons.arrow_downward : Icons.arrow_upward),
                onPressed: () {
                  setState(() {
                    _descending = !_descending;
                  });
                  _fetchHistory();
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced UI for each history item.
  Widget _buildEnhancedItem(Map<String, dynamic> doc) {
    final customerName = doc['customerName'] ?? 'Unknown';
    final currentStatus = doc['currentStatus'] ?? 'N/A';
    final phone = doc['phoneNumber'] ?? '';
    final productCategory = doc['productCategory'] ?? '';
    final createdAtTs = doc['createdAt'] as Timestamp?;
    final createdAt = createdAtTs?.toDate();
    final dateStr = createdAt != null ? DateFormat('yyyy-MM-dd').format(createdAt) : '--';

    // Determine next status for update button.
    final nextStatus = _getNextStatus(currentStatus);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to detailed view when tapped.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SaleHistoryDetailScreen(historyDoc: doc),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Customer Name and Date.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Product and phone details.
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      productCategory,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              // Current status and update button.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  if (nextStatus != null)
                    ElevatedButton(
                      onPressed: () => _updateStatus(doc),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('$nextStatus'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Button to view complete details.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SaleHistoryDetailScreen(historyDoc: doc),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Search Field.
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search by Customer',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                          _fetchHistory();
                        },
                      ),
                    ),
                    // Filter & Sort Options.
                    _buildFilterSortOptions(),
                    // List of history items.
                    _items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No history found.')),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _items.length,
                            itemBuilder: (ctx, i) => _buildEnhancedItem(_items[i]),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
