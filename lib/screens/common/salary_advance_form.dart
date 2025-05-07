// lib/screens/salary_advance_form.dart

// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:z_emp/models/salary_advance_model.dart';
import 'package:z_emp/models/user_model.dart';
import 'package:z_emp/providers/user_provider.dart';
import 'package:z_emp/services/salary_advance_service.dart';

class SalaryAdvanceForm extends StatefulWidget {
  const SalaryAdvanceForm({super.key});

  @override
  _SalaryAdvanceFormState createState() => _SalaryAdvanceFormState();
}

class _SalaryAdvanceFormState extends State<SalaryAdvanceForm> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _repaymentOption = 'Single Payment';

  /// For single payment
  DateTime? _repaymentMonth;

  /// For part payment
  DateTime? _repaymentFromMonth;
  DateTime? _repaymentToMonth;

  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Salary Advance'),
        backgroundColor: Colors.indigo,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildForm(context, currentUser),
            ),
    );
  }

  Widget _buildForm(BuildContext context, UserModel currentUser) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // TITLE CARD
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Hi ${currentUser.name},\nPlease fill out the form below to request a salary advance.",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // INPUTS CARD
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Repayment Options
                  _buildRepaymentOptions(),
                  const SizedBox(height: 16),
                  // Attachment
                  _buildAttachmentPicker(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
            ),
            onPressed: () => _submitRequest(context, currentUser),
            label: const Text(
              'Submit Request',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repayment Option',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Radio<String>(
              value: 'Single Payment',
              groupValue: _repaymentOption,
              onChanged: (value) {
                setState(() {
                  _repaymentOption = value!;
                  _repaymentMonth = null;
                  _repaymentFromMonth = null;
                  _repaymentToMonth = null;
                });
              },
            ),
            const Text('Single Payment'),
          ],
        ),
        if (_repaymentOption == 'Single Payment')
          ListTile(
            title: const Text('Repayment Month and Year'),
            subtitle: Text(
              _repaymentMonth != null
                  ? '${_repaymentMonth!.month}/${_repaymentMonth!.year}'
                  : 'Select Month and Year',
            ),
            leading: const Icon(Icons.calendar_month),
            onTap: _pickRepaymentMonth,
          ),
        Row(
          children: [
            Radio<String>(
              value: 'Part Payment',
              groupValue: _repaymentOption,
              onChanged: (value) {
                setState(() {
                  _repaymentOption = value!;
                  _repaymentMonth = null;
                  _repaymentFromMonth = null;
                  _repaymentToMonth = null;
                });
              },
            ),
            const Text('Part Payment'),
          ],
        ),
        if (_repaymentOption == 'Part Payment')
          Column(
            children: [
              ListTile(
                title: const Text('Repayment Start Month and Year'),
                subtitle: Text(
                  _repaymentFromMonth != null
                      ? '${_repaymentFromMonth!.month}/${_repaymentFromMonth!.year}'
                      : 'Select Start Month and Year',
                ),
                leading: const Icon(Icons.calendar_today),
                onTap: _pickRepaymentFromMonth,
              ),
              ListTile(
                title: const Text('Repayment End Month and Year'),
                subtitle: Text(
                  _repaymentToMonth != null
                      ? '${_repaymentToMonth!.month}/${_repaymentToMonth!.year}'
                      : 'Select End Month and Year',
                ),
                leading: const Icon(Icons.calendar_view_month),
                onTap: _pickRepaymentToMonth,
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _pickRepaymentMonth() async {
    /// Disable past months: only current/future months are selectable.
    final today = DateTime.now();
    final pickedDate = await showMonthYearPicker(
      context: context,
      initialDate: _repaymentMonth ?? today,
      // NEW: start from current month
      firstDate: DateTime(today.year, today.month),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _repaymentMonth = pickedDate;
      });
    }
  }

  Future<void> _pickRepaymentFromMonth() async {
    final today = DateTime.now();
    final pickedDate = await showMonthYearPicker(
      context: context,
      initialDate: _repaymentFromMonth ?? today,
      // NEW: start from current month
      firstDate: DateTime(today.year, today.month),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _repaymentFromMonth = pickedDate;
      });
    }
  }

  Future<void> _pickRepaymentToMonth() async {
    if (_repaymentFromMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the repayment start month first'),
        ),
      );
      return;
    }

    final pickedDate = await showMonthYearPicker(
      context: context,
      initialDate: _repaymentToMonth ?? _repaymentFromMonth!,
      // NEW: cannot be earlier than _repaymentFromMonth
      firstDate:
          DateTime(_repaymentFromMonth!.year, _repaymentFromMonth!.month),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _repaymentToMonth = pickedDate;
      });
    }
  }

  Widget _buildAttachmentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFile != null)
          Text(
            'Selected File: ${_selectedFile!.name}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.attach_file),
          label: const Text('Attach Supporting Document'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 63,81,181)),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true, // Ensures bytes are fetched if possible
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
      print('File selected: ${_selectedFile!.name}');
    } else {
      print('File selection canceled');
    }
  }

  Future<void> _submitRequest(BuildContext context, UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate repayment month/year selection
    if (_repaymentOption == 'Single Payment' && _repaymentMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the repayment month')),
      );
      return;
    }
    if (_repaymentOption == 'Part Payment' &&
        (_repaymentFromMonth == null || _repaymentToMonth == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the repayment period')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final salaryAdvanceService =
        Provider.of<SalaryAdvanceService>(context, listen: false);

    final newRequest = SalaryAdvanceModel(
      advanceId: '', // Will be set by the service
      userId: currentUser.userId,
      name: currentUser.name,
      amountRequested: double.parse(_amountController.text),
      dateSubmitted: Timestamp.now(),
      status: 'Pending',
      approvedBy: '',
      approvalDate: null,
      reason: _reasonController.text,
      repaymentOption: _repaymentOption,
      repaymentMonth: _repaymentOption == 'Single Payment'
          ? '${_repaymentMonth!.month}/${_repaymentMonth!.year}'
          : null,
      repaymentFromMonth: _repaymentOption == 'Part Payment'
          ? '${_repaymentFromMonth!.month}/${_repaymentFromMonth!.year}'
          : null,
      repaymentToMonth: _repaymentOption == 'Part Payment'
          ? '${_repaymentToMonth!.month}/${_repaymentToMonth!.year}'
          : null,
      attachmentUrl: '',
    );

    try {
      await salaryAdvanceService.submitSalaryAdvanceRequest(
        newRequest,
        file: _selectedFile,
      );

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary advance request submitted successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e')),
      );
      print('Error submitting request: $e');
    }
  }
}
