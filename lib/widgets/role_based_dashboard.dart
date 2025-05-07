// lib/widgets/role_based_dashboard.dart
import 'package:flutter/material.dart';

class RoleBasedDashboard extends StatelessWidget {
  final String role;

  const RoleBasedDashboard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(16.0),
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: getDashboardOptions(context),
    );
  }

  List<Widget> getDashboardOptions(BuildContext context) {
    switch (role) {
      case 'Admin':
        return [Text('Admin Options')]; // Replace with actual widgets for Admin
      case 'Manager':
        return [Text('Manager Options')]; // Replace with actual widgets for Manager
      case 'Sales Staff':
        return [Text('Sales Staff Options')]; // Replace with actual widgets for Sales Staff
      case 'Measurement Staff':
        return [Text('Measurement Staff Options')]; // Replace with actual widgets for Measurement Staff
      default:
        return [Text('Invalid role')];
    }
  }
}
