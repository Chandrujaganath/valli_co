// lib/screens/salary_advance_form.dart

// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:valli_and_co/models/salary_advance_model.dart';
import 'package:valli_and_co/models/user_model.dart';
import 'package:valli_and_co/providers/user_provider.dart';
import 'package:valli_and_co/services/salary_advance_service.dart';
import 'package:valli_and_co/utils/app_colors.dart';
import 'package:intl/intl.dart';

class SalaryAdvanceForm extends StatefulWidget {
  const SalaryAdvanceForm({super.key});

  @override
  _SalaryAdvanceFormState createState() => _SalaryAdvanceFormState();
}

class _SalaryAdvanceFormState extends State<SalaryAdvanceForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Form field controllers
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
  bool _showSuccessAnimation = false;

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
        backgroundColor: AppColors.indigo,
        elevation: 0,
      ),
      body: _showSuccessAnimation
          ? _buildSuccessScreen()
          : _isSubmitting
              ? _buildLoadingScreen()
              : Container(
                  color: Colors.grey[50],
                  child: SafeArea(
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: _currentStep,
                      controlsBuilder: (context, details) {
                        return _buildStepperControls(details, currentUser);
                      },
                      onStepTapped: (step) {
                        setState(() {
                          _currentStep = step;
                        });
                      },
                      steps: _buildSteps(context, currentUser),
                    ),
                  ),
                ),
    );
  }

  List<Step> _buildSteps(BuildContext context, UserModel currentUser) {
    return [
      Step(
        title: const Text('Enter Amount'),
        content: _buildAmountStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Provide Reason'),
        content: _buildReasonStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Repayment Details'),
        content: _buildRepaymentStep(context),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Supporting Document'),
        content: _buildAttachmentStep(context),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Review & Submit'),
        content: _buildReviewStep(currentUser),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildStepperControls(ControlsDetails details, UserModel currentUser) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        children: [
          if (_currentStep < 4)
            Expanded(
              child: ElevatedButton(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          if (_currentStep == 4)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _submitRequest(context, currentUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit Request'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.indigo),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much do you need?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount in ₹',
              hintText: 'e.g. 10000',
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.indigo, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than zero';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Please ensure the amount requested is within company policy limits.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why do you need a salary advance?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Explain your reason for requesting this advance',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.indigo, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRepaymentStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to repay?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _repaymentOption == 'Single Payment'
                  ? AppColors.indigo
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: RadioListTile<String>(
            title: const Text(
              'Single Payment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Repay the full amount in one go'),
            value: 'Single Payment',
            groupValue: _repaymentOption,
            activeColor: AppColors.indigo,
            onChanged: (value) {
              setState(() {
                _repaymentOption = value!;
                _repaymentFromMonth = null;
                _repaymentToMonth = null;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_repaymentOption == 'Single Payment')
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repayment Month',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickRepaymentMonth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppColors.indigo,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _repaymentMonth != null
                                ? DateFormat('MMMM yyyy')
                                    .format(_repaymentMonth!)
                                : 'Select Month and Year',
                            style: TextStyle(
                              color: _repaymentMonth != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _repaymentOption == 'Part Payment'
                  ? AppColors.indigo
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: RadioListTile<String>(
            title: const Text(
              'Part Payment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Repay in multiple installments'),
            value: 'Part Payment',
            groupValue: _repaymentOption,
            activeColor: AppColors.indigo,
            onChanged: (value) {
              setState(() {
                _repaymentOption = value!;
                _repaymentMonth = null;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_repaymentOption == 'Part Payment')
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repayment Period',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _pickRepaymentFromMonth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppColors.indigo,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _repaymentFromMonth != null
                                            ? DateFormat('MMM yyyy')
                                                .format(_repaymentFromMonth!)
                                            : 'Start',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _repaymentFromMonth != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _pickRepaymentToMonth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppColors.indigo,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _repaymentToMonth != null
                                            ? DateFormat('MMM yyyy')
                                                .format(_repaymentToMonth!)
                                            : 'End',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _repaymentToMonth != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach Supporting Document (Optional)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You may attach any document that supports your request',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedFile != null)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(_selectedFile!.name),
                    size: 36,
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getFileSize(_selectedFile!.size),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          )
        else
          Center(
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: _pickFile,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: AppColors.indigo,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to select a file',
                      style: TextStyle(
                        color: AppColors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, Word, Excel or Image files',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_selectedFile == null)
          Center(
            child: TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Browse Files'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.indigo,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return Icons.image;
    } else if (['pdf'].contains(extension)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(extension)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(extension)) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Widget _buildReviewStep(UserModel currentUser) {
    final amount =
        _amountController.text.isEmpty ? '0' : _amountController.text;
    final reason = _reasonController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Request',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₹${double.parse(amount).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Employee Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Repayment Option',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _repaymentOption,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_repaymentOption == 'Single Payment' &&
                    _repaymentMonth != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Repayment Month',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_repaymentMonth!),
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                if (_repaymentOption == 'Part Payment' &&
                    _repaymentFromMonth != null &&
                    _repaymentToMonth != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Repayment Period',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM yyyy').format(_repaymentFromMonth!)} to ${DateFormat('MMM yyyy').format(_repaymentToMonth!)}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                if (_selectedFile != null) const Divider(height: 24),
                if (_selectedFile != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attachment',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _selectedFile!.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.indigo,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'By submitting this request, you agree to the terms of the company\'s salary advance policy.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Submitting your request...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Request Submitted!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your salary advance request has been submitted successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
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

  Future<void> _submitRequest(
      BuildContext context, UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) {
      // Go back to the first step if validation fails
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    // Validate repayment month/year selection
    if (_repaymentOption == 'Single Payment' && _repaymentMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the repayment month')),
      );
      setState(() {
        _currentStep = 2;
      });
      return;
    }
    if (_repaymentOption == 'Part Payment' &&
        (_repaymentFromMonth == null || _repaymentToMonth == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the repayment period')),
      );
      setState(() {
        _currentStep = 2;
      });
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

      setState(() {
        _isSubmitting = false;
        _showSuccessAnimation = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e')),
      );
      print('Error submitting request: $e');
    }
  }
}
