import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// CSV
import 'package:csv/csv.dart';

// PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Paths
import 'package:path_provider/path_provider.dart';

// Services
import 'package:z_emp/services/attendance_service.dart';
import 'package:z_emp/services/sales_service.dart';
import 'package:z_emp/services/enquiry_service.dart';
import 'package:z_emp/services/salary_advance_service.dart';
import 'package:z_emp/services/leave_request_service.dart';
import 'package:z_emp/services/task_service.dart';

/// Simple date range class
class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({Key? key}) : super(key: key);

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  // Available time ranges
  String _selectedRange = 'Last Month';

  // Which modules are selected
  bool _attendanceSelected = true;
  bool _salesSelected = true;
  bool _enquirySelected = true;
  bool _salarySelected = true;
  bool _leaveSelected = true;
  bool _taskSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Premium gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4B79A1), Color(0xFF283E51)], // bluish gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: _buildContentCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Generate Reports',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16.0),

            // Premium dropdown row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  'Select Range:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                _buildRangeDropdown(),
              ],
            ),
            const SizedBox(height: 24),

            // Checkboxes for modules
            _buildModuleSelection(),

            const SizedBox(height: 24),

            // CSV and PDF Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: _selectedRange,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: 'Last Month',
            child: Text('Last Month'),
          ),
          DropdownMenuItem(
            value: 'Last 3 Months',
            child: Text('Last 3 Months'),
          ),
          DropdownMenuItem(
            value: 'All Time',
            child: Text('All Time'),
          ),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedRange = val);
          }
        },
      ),
    );
  }

  Widget _buildModuleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Modules:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 8),
        _buildCheckboxTile(
          title: 'Attendance Records',
          value: _attendanceSelected,
          onChanged: (val) => setState(() => _attendanceSelected = val!),
        ),
        _buildCheckboxTile(
          title: 'Sales',
          value: _salesSelected,
          onChanged: (val) => setState(() => _salesSelected = val!),
        ),
        _buildCheckboxTile(
          title: 'Enquiries',
          value: _enquirySelected,
          onChanged: (val) => setState(() => _enquirySelected = val!),
        ),
        _buildCheckboxTile(
          title: 'Salary Advances',
          value: _salarySelected,
          onChanged: (val) => setState(() => _salarySelected = val!),
        ),
        _buildCheckboxTile(
          title: 'Leave Requests',
          value: _leaveSelected,
          onChanged: (val) => setState(() => _leaveSelected = val!),
        ),
        _buildCheckboxTile(
          title: 'Tasks (Performance)',
          value: _taskSelected,
          onChanged: (val) => setState(() => _taskSelected = val!),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blueAccent,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // CSV Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.file_copy),
          label: const Text('Generate CSV'),
          onPressed: () => _confirmGeneration(context, isPdf: false),
        ),

        // PDF Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Generate PDF'),
          onPressed: () => _confirmGeneration(context, isPdf: true),
        ),
      ],
    );
  }

  /// Confirm with user before generating
  void _confirmGeneration(BuildContext context, {required bool isPdf}) {
    final modules = <String>[];
    if (_attendanceSelected) modules.add('Attendance');
    if (_salesSelected) modules.add('Sales');
    if (_enquirySelected) modules.add('Enquiries');
    if (_salarySelected) modules.add('Salary Advances');
    if (_leaveSelected) modules.add('Leave Requests');
    if (_taskSelected) modules.add('Tasks');

    if (modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one module.'),
        ),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Generation'),
        content: Text(
          'You selected the following modules:\n\n${modules.join(', ')}\n\nDo you want to generate a ${isPdf ? 'PDF' : 'CSV'} report for "${_selectedRange}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        if (isPdf) {
          _generateReportPDF(context);
        } else {
          _generateReportCSV(context);
        }
      }
    });
  }

  // --------------------------------------------------------------------------
  // Get the selected date range
  // --------------------------------------------------------------------------
  DateRange _getDateRange(String label) {
    final now = DateTime.now();
    if (label == 'Last Month') {
      return DateRange(now.subtract(const Duration(days: 30)), now);
    } else if (label == 'Last 3 Months') {
      return DateRange(now.subtract(const Duration(days: 90)), now);
    } else {
      return DateRange(DateTime(1970, 1, 1), now);
    }
  }

  // --------------------------------------------------------------------------
  // CSV logic
  // --------------------------------------------------------------------------
  Future<void> _generateReportCSV(BuildContext context) async {
    final dateRange = _getDateRange(_selectedRange);
    final startDate = dateRange.start;
    final endDate = dateRange.end;

    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final salesService = Provider.of<SalesService>(context, listen: false);
    final enquiryService = Provider.of<EnquiryService>(context, listen: false);
    final salaryAdvanceService = Provider.of<SalaryAdvanceService>(context, listen: false);
    final leaveService = Provider.of<LeaveRequestService>(context, listen: false);
    final taskService = Provider.of<TaskService>(context, listen: false);

    // 1) Fetch
    final allAttendance = await attendanceService.getAttendanceRecords();
    final allSales = await salesService.getSales();
    final allEnquiries = await enquiryService.getAllEnquiries();
    final allAdvances = await salaryAdvanceService.getSalaryAdvances();
    final allLeaves = await leaveService.getLeaveRequests();
    final allTasks = await taskService.getAllTasks();

    // 2) Filter
    final attendanceInRange = allAttendance.where((a) {
      final dt = a.clockIn.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final salesInRange = allSales.where((s) {
      return s.salesDate.isAfter(startDate) && s.salesDate.isBefore(endDate);
    }).toList();

    final enquiriesInRange = allEnquiries.where((e) {
      final dt = e.enquiryDate.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final advInRange = allAdvances.where((adv) {
      final dt = adv.dateSubmitted.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final leavesInRange = allLeaves.where((l) {
      final dt = l.dateSubmitted.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final tasksInRange = allTasks.where((t) {
      final dt = t.createdAt.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final List<List<dynamic>> csvData = [];

    // Only add sections for selected modules:
    if (_attendanceSelected) {
      csvData.add(['=== Attendance Records ===']);
      csvData.add(['UserId', 'Name', 'ClockIn', 'ClockOut', 'Status', 'BranchId']);
      for (var a in attendanceInRange) {
        csvData.add([
          a.userId,
          a.name,
          a.clockIn.toDate().toString(),
          a.clockOut?.toDate().toString() ?? '',
          a.status,
          a.branchId,
        ]);
      }
      csvData.add([]);
    }

    if (_salesSelected) {
      csvData.add(['=== Sales ===']);
      csvData.add(['SaleId', 'SalesDate', 'ProductCategory', 'TotalCashSales']);
      for (var s in salesInRange) {
        csvData.add([
          s.saleId,
          s.salesDate.toString(),
          s.productCategory,
          s.totalCashSales,
        ]);
      }
      csvData.add([]);
    }

    if (_enquirySelected) {
      csvData.add(['=== Enquiries ===']);
      csvData.add(['EnquiryId', 'CustomerName', 'EnquiryDate', 'Status']);
      for (var e in enquiriesInRange) {
        csvData.add([
          e.enquiryId,
          e.customerName,
          e.enquiryDate.toDate().toString(),
          e.status,
        ]);
      }
      csvData.add([]);
    }

    if (_salarySelected) {
      csvData.add(['=== Salary Advances ===']);
      csvData.add(['AdvanceId', 'UserId', 'Name', 'AmountRequested', 'DateSubmitted', 'Status']);
      for (var adv in advInRange) {
        csvData.add([
          adv.advanceId,
          adv.userId,
          adv.name,
          adv.amountRequested,
          adv.dateSubmitted.toDate().toString(),
          adv.status,
        ]);
      }
      csvData.add([]);
    }

    if (_leaveSelected) {
      csvData.add(['=== Leave Requests ===']);
      csvData.add(['LeaveId', 'UserId', 'StartDate', 'EndDate', 'Status']);
      for (var l in leavesInRange) {
        csvData.add([
          l.leaveId,
          l.userId,
          l.startDate.toDate().toString(),
          l.endDate.toDate().toString(),
          l.status,
        ]);
      }
      csvData.add([]);
    }

    if (_taskSelected) {
      csvData.add(['=== Tasks ===']);
      csvData.add(['TaskId', 'AssignedTo', 'Status', 'CreatedAt']);
      for (var t in tasksInRange) {
        csvData.add([
          t.taskId,
          t.assignedTo,
          t.status,
          t.createdAt.toDate().toString(),
        ]);
      }
      csvData.add([]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);

    final fileName = 'Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final csvFile = await _saveFileToDownloads(fileName, csvString.codeUnits);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV saved to: ${csvFile.path}')),
    );
  }

  // --------------------------------------------------------------------------
  // PDF logic
  // --------------------------------------------------------------------------
  Future<void> _generateReportPDF(BuildContext context) async {
    final dateRange = _getDateRange(_selectedRange);
    final startDate = dateRange.start;
    final endDate = dateRange.end;

    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final salesService = Provider.of<SalesService>(context, listen: false);
    final enquiryService = Provider.of<EnquiryService>(context, listen: false);
    final salaryAdvanceService = Provider.of<SalaryAdvanceService>(context, listen: false);
    final leaveService = Provider.of<LeaveRequestService>(context, listen: false);
    final taskService = Provider.of<TaskService>(context, listen: false);

    // 1) Fetch
    final allAttendance = await attendanceService.getAttendanceRecords();
    final allSales = await salesService.getSales();
    final allEnquiries = await enquiryService.getAllEnquiries();
    final allAdvances = await salaryAdvanceService.getSalaryAdvances();
    final allLeaves = await leaveService.getLeaveRequests();
    final allTasks = await taskService.getAllTasks();

    // 2) Filter
    final attendanceInRange = allAttendance.where((a) {
      final dt = a.clockIn.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final salesInRange = allSales.where((s) {
      return s.salesDate.isAfter(startDate) && s.salesDate.isBefore(endDate);
    }).toList();

    final enquiriesInRange = allEnquiries.where((e) {
      final dt = e.enquiryDate.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final advInRange = allAdvances.where((adv) {
      final dt = adv.dateSubmitted.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final leavesInRange = allLeaves.where((l) {
      final dt = l.dateSubmitted.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    final tasksInRange = allTasks.where((t) {
      final dt = t.createdAt.toDate();
      return dt.isAfter(startDate) && dt.isBefore(endDate);
    }).toList();

    // 3) Build PDF
    final pdfDoc = pw.Document();
    pdfDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          final content = <pw.Widget>[
            pw.Center(
              child: pw.Text(
                'Z Emp Report ($_selectedRange)',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
          ];

          // Add selected modules only
          if (_attendanceSelected) {
            content.addAll([
              pw.Text('Attendance Records',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _tableFromAttendance(attendanceInRange),
              pw.SizedBox(height: 10),
            ]);
          }
          if (_salesSelected) {
            content.addAll([
              pw.Text('Sales',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _tableFromSales(salesInRange),
              pw.SizedBox(height: 10),
            ]);
          }
          if (_enquirySelected) {
            content.addAll([
              pw.Text('Enquiries',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _tableFromEnquiries(enquiriesInRange),
              pw.SizedBox(height: 10),
            ]);
          }
          if (_salarySelected) {
            content.addAll([
              pw.Text('Salary Advances',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _tableFromAdvances(advInRange),
              pw.SizedBox(height: 10),
            ]);
          }
          if (_leaveSelected) {
            content.addAll([
              pw.Text('Leave Requests',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _tableFromLeaves(leavesInRange),
              pw.SizedBox(height: 10),
            ]);
          }
          if (_taskSelected) {
            content.addAll([
              pw.Text('Tasks',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              _tableFromTasks(tasksInRange),
              pw.SizedBox(height: 10),
            ]);
          }

          return content;
        },
      ),
    );

    final fileName = 'Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfBytes = await pdfDoc.save();
    final pdfFile = await _saveFileToDownloads(fileName, pdfBytes);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to: ${pdfFile.path}')),
    );
  }

  // PDF table helpers
  pw.Widget _tableFromAttendance(List<dynamic> list) {
    return pw.Table.fromTextArray(
      headers: ['UserId', 'Name', 'ClockIn', 'ClockOut', 'Status'],
      data: list.map((a) {
        return [
          a.userId,
          a.name,
          a.clockIn.toDate().toString(),
          a.clockOut?.toDate().toString() ?? '',
          a.status,
        ];
      }).toList(),
    );
  }

  pw.Widget _tableFromSales(List<dynamic> list) {
    return pw.Table.fromTextArray(
      headers: ['SaleId', 'SalesDate', 'Product', 'CashSales'],
      data: list.map((s) {
        return [
          s.saleId,
          s.salesDate.toString(),
          s.productCategory,
          s.totalCashSales.toString(),
        ];
      }).toList(),
    );
  }

  pw.Widget _tableFromEnquiries(List<dynamic> list) {
    return pw.Table.fromTextArray(
      headers: ['EnquiryId', 'CustomerName', 'EnquiryDate', 'Status'],
      data: list.map((e) {
        return [
          e.enquiryId,
          e.customerName,
          e.enquiryDate.toDate().toString(),
          e.status,
        ];
      }).toList(),
    );
  }

  pw.Widget _tableFromAdvances(List<dynamic> list) {
    return pw.Table.fromTextArray(
      headers: ['AdvanceId', 'UserId', 'Name', 'AmountRequested', 'DateSubmitted', 'Status'],
      data: list.map((adv) {
        return [
          adv.advanceId,
          adv.userId,
          adv.name,
          adv.amountRequested.toString(),
          adv.dateSubmitted.toDate().toString(),
          adv.status,
        ];
      }).toList(),
    );
  }

  pw.Widget _tableFromLeaves(List<dynamic> list) {
    return pw.Table.fromTextArray(
      headers: ['LeaveId', 'UserId', 'StartDate', 'EndDate', 'Status'],
      data: list.map((l) {
        return [
          l.leaveId,
          l.userId,
          l.startDate.toDate().toString(),
          l.endDate.toDate().toString(),
          l.status,
        ];
      }).toList(),
    );
  }

  pw.Widget _tableFromTasks(List<dynamic> list) {
    return pw.Table.fromTextArray(
      headers: ['TaskId', 'AssignedTo', 'Status', 'CreatedAt'],
      data: list.map((t) {
        return [
          t.taskId,
          t.assignedTo,
          t.status,
          t.createdAt.toDate().toString(),
        ];
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // Save file to Downloads (Android) or Documents (iOS)
  // --------------------------------------------------------------------------
  Future<File> _saveFileToDownloads(String fileName, List<int> bytes) async {
    late Directory dir;

    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } else {
      // iOS/macOS
      dir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
}
