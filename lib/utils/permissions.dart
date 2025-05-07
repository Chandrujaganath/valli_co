// lib/utils/permissions.dart

import 'constants.dart';

class Permissions {
  // Checks if a user can manage other users (Admin role only)
  static bool canManageUsers(String role) {
    return role == UserRoles.admin;
  }

  // Checks if a user can approve tasks (Admin or Manager roles)
  static bool canApproveTasks(String role) {
    return role == UserRoles.manager || role == UserRoles.admin;
  }

  // Checks if a user can submit sales data (Sales Staff role)
  static bool canSubmitSalesData(String role) {
    return role == UserRoles.salesStaff;
  }

  // Checks if a user can log measurements (Measurement Staff role)
  static bool canLogMeasurements(String role) {
    return role == UserRoles.measurementStaff;
  }

  // Checks if a user can view reports (Admin and Manager roles)
  static bool canViewReports(String role) {
    return role == UserRoles.admin || role == UserRoles.manager;
  }

  // Checks if a user can request a salary advance (Sales Staff or Measurement Staff roles)
  static bool canRequestSalaryAdvance(String role) {
    return role == UserRoles.salesStaff || role == UserRoles.measurementStaff;
  }

  // Checks if a user can submit leave requests (Sales Staff or Measurement Staff roles)
  static bool canSubmitLeaveRequest(String role) {
    return role == UserRoles.salesStaff || role == UserRoles.measurementStaff;
  }
}
