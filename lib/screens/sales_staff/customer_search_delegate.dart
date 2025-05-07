// lib/screens/sales_staff/customer_search_delegate.dart

import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
 // Adjust the import path as needed

class CustomerSearchDelegate extends SearchDelegate<CustomerModel?> {
  final List<CustomerModel> customers;
  final Function(CustomerModel) onSelected;

  CustomerSearchDelegate({
    required this.customers,
    required this.onSelected,
  });

  @override
  String get searchFieldLabel => 'Search Customers';

  @override
  TextStyle get searchFieldStyle => const TextStyle(fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = customers.where((customer) {
      final lowerQuery = query.toLowerCase();
      return customer.name.toLowerCase().contains(lowerQuery) ||
          customer.phone.toLowerCase().contains(lowerQuery) ||
          customer.email.toLowerCase().contains(lowerQuery) ||
          customer.address.toLowerCase().contains(lowerQuery);
    }).toList();

    return _buildCustomerList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = customers.where((customer) {
      final lowerQuery = query.toLowerCase();
      return customer.name.toLowerCase().contains(lowerQuery) ||
          customer.phone.toLowerCase().contains(lowerQuery) ||
          customer.email.toLowerCase().contains(lowerQuery) ||
          customer.address.toLowerCase().contains(lowerQuery);
    }).toList();

    return _buildCustomerList(suggestions);
  }

  Widget _buildCustomerList(List<CustomerModel> customerList) {
    if (customerList.isEmpty) {
      return const Center(child: Text('No customers found.'));
    }
    return ListView.builder(
      itemCount: customerList.length,
      itemBuilder: (context, index) {
        final customer = customerList[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: Text('Phone: ${customer.phone}\nEmail: ${customer.email}'),
          onTap: () {
            onSelected(customer);
            close(context, customer);
          },
        );
      },
    );
  }
}
