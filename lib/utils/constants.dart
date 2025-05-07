// lib/utils/constants.dart

class FirestoreCollections {
  static const String users = 'users';
  static const String enquiries = 'enquiries';
  static const String sales = 'sales';
  static const String measurements = 'measurements';
  static const String leaveRequests = 'leaveRequests';
  static const String salaryAdvances = 'salaryAdvances';
  static const String attendanceRecords = 'attendanceRecords';
  static const String tasks = 'tasks';
  static const String performance = 'performance';
  static const String branches = 'branches'; // Add branches collection
  static const String announcements = 'announcements'; // Add announcements collection
}

class UserRoles {
  static const String admin = 'Admin';
  static const String manager = 'Manager';
  static const String salesStaff = 'Sales Staff';
  static const String measurementStaff = 'Measurement Staff';
}

class Statuses {
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String completed = 'Completed';
  static const String delayed = 'Delayed';
  static const String onTime = 'On Time';
}

class TaskStatuses {
  static const String mtbt = 'MTBT'; // Measurement Task Before Time
  static const String mok = 'MOK';   // Measurement OK
}

class LeaveTypes {
  static const String sickLeave = 'Sick Leave';
  static const String annualLeave = 'Annual Leave';
  static const String casualLeave = 'Casual Leave';
}

class AttendanceStatus {
  static const String onTime = 'On Time';
  static const String late = 'Late';
}

class SalesStatus {
  static const String cash = 'Cash';
  static const String credit = 'Credit';
}
