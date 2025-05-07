import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:z_emp/providers/app_settings_provider.dart';

// Import modern dashboards
import '../admin/modern_admin_dashboard.dart';
import '../manager/modern_manager_dashboard.dart';
import '../sales_staff/sales_dashboard_content.dart';
import '../measurement_staff/measurement_dashboard_content.dart';

import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Error retrieving user data.')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userRole = userData['role'] as String?;

        if (userRole == null || userRole.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('User role not defined.')),
          );
        }

        // Always use modern dashboards
        switch (userRole) {
          case 'admin':
          case 'Admin':
            return const ModernAdminDashboard();
          case 'manager':
          case 'Manager':
            return const ModernManagerDashboard();
          case 'sales staff':
          case 'Sales Staff':
            return const SalesDashboardContent(); // Using the wrapper that returns ModernSalesDashboard
          case 'measurement staff':
          case 'Measurement Staff':
            return const MeasurementDashboardContent(); // Using the wrapper that returns ModernMeasurementDashboard
          default:
            return const Scaffold(
              body: Center(child: Text('Invalid role.')),
            );
        }
      },
    );
  }
}
