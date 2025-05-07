// lib/screens/sales_staff/customer_details_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:z_emp/screens/sales_staff/customer_search_delegate.dart';

import '../../services/customer_service.dart';
import '../../services/sales_service.dart';
import '../../models/customer_model.dart';
import '../../models/sales_model.dart';

/// Main screen to list customers and navigate to details
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<CustomerModel> customers = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final customerService = Provider.of<CustomerService>(context, listen: false);
      customers = await customerService.getAllCustomersOnce();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load customers.';
      });
    }
  }

  void _navigateToCustomerDetails(CustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Customer',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
              );
              _fetchCustomers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Customers',
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomerSearchDelegate(
                  customers: customers,
                  onSelected: _navigateToCustomerDetails,
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : customers.isEmpty
                  ? const Center(child: Text('No customers found.'))
                  : RefreshIndicator(
                      onRefresh: _fetchCustomers,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
                    ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    final name = customer.name.isNotEmpty ? customer.name : 'Unnamed';
    final initial = name[0].toUpperCase();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade600,
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Phone: ${customer.phone}\nEmail: ${customer.email.isEmpty ? 'N/A' : customer.email}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        onTap: () => _navigateToCustomerDetails(customer),
      ),
    );
  }
}

/// Shows customer details (basic info & sales) in a tab view.
class CustomerDetailsScreen extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<SalesModel>> _salesFuture;
  bool isEditing = false;
  late CustomerModel customer;

  @override
  void initState() {
    super.initState();
    customer = widget.customer;
    _tabController = TabController(length: 2, vsync: this);
    _salesFuture = _fetchSales();
  }

  /// Retrieves sales for this customer.
  Future<List<SalesModel>> _fetchSales() {
    final salesService = Provider.of<SalesService>(context, listen: false);
    return salesService.getSalesByCustomer(customer.customerId);
  }


  void _toggleEdit() => setState(() => isEditing = !isEditing);

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final customerService = Provider.of<CustomerService>(context, listen: false);
        await customerService.deleteCustomer(customer.customerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting customer: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Sales'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.cancel : Icons.edit),
            onPressed: _toggleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isEditing ? _buildEditProfile() : _buildProfileDetails(),
          _buildSalesData(),
        ],
      ),
    );
  }

  // ---------------------
  // DETAILS TAB
  // ---------------------
  Widget _buildProfileDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoCard(),
          const SizedBox(height: 20),
          FutureBuilder<SalesSummary>(
            future: _getSalesSummary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Text('Error loading sales summary.');
              } else if (!snapshot.hasData) {
                return const Text('No sales data available.');
              } else {
                final summary = snapshot.data!;
                return _buildSalesSummaryCard(summary);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _detailRow('Name', customer.name),
            const SizedBox(height: 8),
            _detailRow('Phone', customer.phone),
            const SizedBox(height: 8),
            _detailRow('Email', customer.email.isNotEmpty ? customer.email : 'N/A'),
            const SizedBox(height: 8),
            _detailRow('Address', customer.address),
            const SizedBox(height: 8),
            _detailRow(
              'Registered On',
              DateFormat('yyyy-MM-dd').format(_getDate(customer.registrationDate)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildSalesSummaryCard(SalesSummary summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Sales: ₹${summary.totalSales.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Transactions: ${summary.transactionCount}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text('Avg Transaction: ₹${summary.averageTransaction.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<SalesSummary> _getSalesSummary() async {
    final sales = await _fetchSales();
    if (sales.isEmpty) {
      return SalesSummary(totalSales: 0, transactionCount: 0, averageTransaction: 0);
    }
    final total = sales.fold(0.0, (sum, sale) => sum + sale.crAmount);
    final count = sales.length;
    return SalesSummary(totalSales: total, transactionCount: count, averageTransaction: total / count);
  }

  // ---------------------
  // EDIT TAB
  // ---------------------
  Widget _buildEditProfile() {
    final formKey = GlobalKey<FormState>();
    String name = customer.name;
    String phone = customer.phone;
    String email = customer.email;
    String address = customer.address;

    Future<void> submitForm() async {
      if (!formKey.currentState!.validate()) return;
      formKey.currentState!.save();
      final customerService = Provider.of<CustomerService>(context, listen: false);
      final updatedCustomer = CustomerModel(
        customerId: customer.customerId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        registrationDate: customer.registrationDate,
      );
      try {
        await customerService.updateCustomer(updatedCustomer);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully.')),
        );
        setState(() {
          customer = updatedCustomer;
          isEditing = false;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating customer: $e')),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
              onSaved: (value) => name = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: phone,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter a phone number';
                final cleaned = value.trim();
                if (cleaned.length != 10 || RegExp(r'[^0-9]').hasMatch(cleaned)) {
                  return 'Phone number must be exactly 10 digits';
                }
                return null;
              },
              onSaved: (value) => phone = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: email,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                }
                return null;
              },
              onSaved: (value) => email = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: address,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter an address' : null,
              onSaved: (value) => address = value!.trim(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------
  // SALES TAB
  // ---------------------
  Widget _buildSalesData() {
    return FutureBuilder<List<SalesModel>>(
      future: _salesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching sales data: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sales data found.'));
        } else {
          final sales = snapshot.data!;
          final chartData = _generateChartData(sales);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LineChart(_buildLineChartData(chartData)),
                ),
                const SizedBox(height: 20),
                _buildSalesList(sales),
              ],
            ),
          );
        }
      },
    );
  }

  // Creates a line chart with a gradient fill.
  LineChartData _buildLineChartData(List<FlSpot> chartData) {
    final gradientColors = [
      Colors.blue.withOpacity(0.5),
      Colors.cyan.withOpacity(0.2),
    ];
    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      gridData: FlGridData(show: true, horizontalInterval: 50),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              final formattedDate = DateFormat('MM-dd').format(date);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(formattedDate, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: chartData,
          isCurved: true,
          gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  /// Aggregates sales by date for this customer.
  List<FlSpot> _generateChartData(List<SalesModel> sales) {
    final Map<int, double> salesByDate = {};
    for (var sale in sales) {
      final date = _getDate(sale.salesDate);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final timestamp = normalizedDate.millisecondsSinceEpoch;
      salesByDate[timestamp] = (salesByDate[timestamp] ?? 0) + sale.crAmount;
    }
    final data = salesByDate.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    data.sort((a, b) => a.x.compareTo(b.x));
    return data;
  }

  // Builds a scrollable list of the customer's sales.
  Widget _buildSalesList(List<SalesModel> sales) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return _buildSalesCard(sale);
      },
    );
  }

  // Enhanced card with color-coded status.
  Widget _buildSalesCard(SalesModel sale) {
    final statusColor = _getStatusColor(sale.salesStatus);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.attach_money, color: Colors.white),
        ),
        title: Text(
          'Product: ${sale.productsSold}', // You might want to format this list
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Amount: ₹${sale.crAmount.toStringAsFixed(2)}\nStatus: ${sale.salesStatus}',
        ),
        trailing: Text(
          DateFormat('yyyy-MM-dd').format(_getDate(sale.salesDate)),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'payment done':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  /// Helper method to safely extract a DateTime from a field.
  DateTime _getDate(dynamic field) {
    if (field is Timestamp) return field.toDate();
    if (field is DateTime) return field;
    return DateTime.now();
  }
}


/// Add Customer Screen (with slight styling improvements).
class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();
  final TextEditingController customerAddressController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    customerNameController.dispose();
    customerPhoneController.dispose();
    customerEmailController.dispose();
    customerAddressController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);
    final customerService = Provider.of<CustomerService>(context, listen: false);
    final docId = FirebaseFirestore.instance.collection('customers').doc().id;
    final newCustomer = CustomerModel(
      customerId: docId,
      name: customerNameController.text.trim(),
      phone: customerPhoneController.text.trim(),
      email: customerEmailController.text.trim(),
      address: customerAddressController.text.trim(),
      registrationDate: Timestamp.now(),
    );
    try {
      await customerService.addCustomer(newCustomer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding customer: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    TextFormField(
                      controller: customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Please enter a name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        final phone = value.trim();
                        if (phone.length != 10 || RegExp(r'[^0-9]').hasMatch(phone)) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: customerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: customerAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Please enter an address'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Add Customer'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Model for aggregated sales summary.
class SalesSummary {
  final double totalSales;
  final int transactionCount;
  final double averageTransaction;

  SalesSummary({
    required this.totalSales,
    required this.transactionCount,
    required this.averageTransaction,
  });
}
