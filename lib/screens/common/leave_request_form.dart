// lib/screens/common/leave_request_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/leave_request_service.dart';
import '../../models/leave_request_model.dart';

class LeaveRequestForm extends StatefulWidget {
  const LeaveRequestForm({super.key});

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm>
    with TickerProviderStateMixin {
  final TextEditingController reasonController = TextEditingController();
  String leaveType = 'Sick Leave';
  String dayType = 'Full Day';
  DateTime? startDate;
  DateTime? endDate;
  String? userName;

  late TabController _tabController;
  bool _isSubmitting = false;
  bool _isDataLoading = true;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // UI constants
  final _primaryGradient = const LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _secondaryGradient = const LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // Color scheme
  final Color _primaryColor = const Color(0xFF6A11CB);
  final Color _accentColor = const Color(0xFF2575FC);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _dangerColor = const Color(0xFFF44336);
  final Color _warningColor = const Color(0xFFFF9800);
  final Color _textPrimaryColor = const Color(0xFF333333);
  final Color _textSecondaryColor = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();

    // Tab controller for Full Day/Half Day selection
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          dayType = _tabController.index == 0 ? 'Full Day' : 'Half Day';

          // For half day, set end date same as start date
          if (dayType == 'Half Day' && startDate != null) {
            endDate = startDate;
          }
        });
      }
    });

    // Animation controller for fade-in effects
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fetchUserName();
    _animationController.forward();
  }

  @override
  void dispose() {
    reasonController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    setState(() => _isDataLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (!mounted) return;
        setState(() {
          userName = userDoc['name'] ?? 'User';
          _isDataLoading = false;
          _errorMessage = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          userName = 'User';
          _isDataLoading = false;
          _errorMessage = 'Failed to fetch user data: $e';
        });
      }
    } else {
      setState(() {
        _isDataLoading = false;
        _errorMessage = 'No user is currently logged in';
      });
    }
  }

  /// Opens a date picker for either the start or end date.
  /// Allows any date from 2000 to 2101 (including past dates).
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2101);

    // Use whichever date is currently selected if available; otherwise default to "now"
    final initialDate =
        isStart ? (startDate ?? now) : (endDate ?? (startDate ?? now));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: _textPrimaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          startDate = pickedDate;

          // If half day or end date is before the new start date,
          // update the end date to match the start date
          if (dayType == 'Half Day' ||
              (endDate != null && endDate!.isBefore(startDate!))) {
            endDate = pickedDate;
          }
        } else {
          endDate = pickedDate;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to request leave.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final leaveRequestService =
        Provider.of<LeaveRequestService>(context, listen: false);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Leave Request',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(gradient: _primaryGradient),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
            ),
          ];
        },
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: _secondaryGradient),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _isDataLoading
                    ? _buildLoadingState()
                    : (_errorMessage != null)
                        ? _buildErrorState()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderTitle(),
                                const SizedBox(height: 24),
                                _buildLeaveDetailsCard(context, currentUser.uid,
                                    leaveRequestService),
                                const SizedBox(height: 32),
                                _buildPreviousRequestsSection(
                                    currentUser.uid, leaveRequestService),
                              ],
                            ),
                          ),
              ),
            ),
            if (_isSubmitting)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _primaryColor),
                          const SizedBox(height: 24),
                          Text(
                            'Submitting your leave request...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: _dangerColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchUserName,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_available,
                color: _primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Submit Leave Request',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Text(
            'Please fill in the details below to request leave',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveDetailsCard(
    BuildContext context,
    String userId,
    LeaveRequestService leaveRequestService,
  ) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Selector for Full Day / Half Day
          Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: _primaryColor,
                indicatorWeight: 3,
                labelColor: _primaryColor,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelColor: _textSecondaryColor,
                tabs: const [
                  Tab(text: 'Full Day'),
                  Tab(text: 'Half Day'),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leave Type Dropdown
                _buildDropdownField(
                  label: 'Leave Type',
                  value: leaveType,
                  hint: 'Select leave type',
                  icon: Icons.category,
                  items: const [
                    DropdownMenuItem(
                        value: 'Sick Leave', child: Text('Sick Leave')),
                    DropdownMenuItem(
                        value: 'Personal Leave', child: Text('Personal Leave')),
                    DropdownMenuItem(
                        value: 'Vacation', child: Text('Vacation')),
                    DropdownMenuItem(
                        value: 'Family Emergency',
                        child: Text('Family Emergency')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => leaveType = value);
                  },
                ),
                const SizedBox(height: 24),

                // Date Pickers Section
                if (dayType == 'Full Day')
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Start Date',
                          date: startDate,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: 'End Date',
                          date: endDate,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  )
                else
                  _buildDateField(
                    label: 'Date',
                    date: startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),

                const SizedBox(height: 24),

                // Reason TextField
                _buildTextField(
                  label: 'Reason for Leave',
                  hint: 'Please provide your reason here...',
                  controller: reasonController,
                  maxLines: 4,
                  icon: Icons.description,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _validateAndSubmit(leaveRequestService, userId),
                    icon: const Icon(Icons.send),
                    label: Text(
                      'Submit Leave Request',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, Icons.calendar_today),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date == null ? 'Select Date' : _formatDate(date),
                    style: GoogleFonts.poppins(
                      color: date == null
                          ? Colors.grey.shade600
                          : _textPrimaryColor,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, icon),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: _textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, icon),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
          dropdownColor: Colors.white,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: _textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _validateAndSubmit(
      LeaveRequestService leaveRequestService, String userId) async {
    // Validate inputs
    if (dayType == 'Full Day') {
      // Must have both dates
      if (startDate == null || endDate == null) {
        _showErrorSnackBar('Please select both start and end dates');
        return;
      }
      // For a full-day leave, end date must be after the start date or the same
      if (endDate!.isBefore(startDate!)) {
        _showErrorSnackBar('End date can\'t be before start date');
        return;
      }
    } else {
      // "Half Day" requires only a startDate
      if (startDate == null) {
        _showErrorSnackBar('Please select a date for half-day leave');
        return;
      }
      // For consistency, set endDate to startDate
      endDate = startDate;
    }

    // Reason required
    if (reasonController.text.trim().isEmpty) {
      _showErrorSnackBar('Please provide a reason for your leave request');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await leaveRequestService.submitLeaveRequest(
        userId: userId,
        name: userName ?? 'User',
        leaveType: leaveType,
        startDate: Timestamp.fromDate(startDate!),
        endDate: Timestamp.fromDate(endDate!),
        dayType: dayType,
        reason: reasonController.text.trim(),
      );

      // Reset fields after successful submission
      setState(() {
        reasonController.clear();
        leaveType = 'Sick Leave';
        dayType = _tabController.index == 0 ? 'Full Day' : 'Half Day';
        startDate = null;
        endDate = null;
      });

      _showSuccessSnackBar('Leave request submitted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to submit leave request: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPreviousRequestsSection(
      String userId, LeaveRequestService leaveRequestService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.history,
                color: _primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Previous Leave Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<LeaveRequestModel>>(
          stream: leaveRequestService.getUserLeaveRequests(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildHistoryLoadingState();
            } else if (snapshot.hasError) {
              return _buildHistoryErrorState(snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildHistoryEmptyState();
            } else {
              final requests = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildLeaveRequestCard(requests[index]),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHistoryLoadingState() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading your leave history...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryErrorState(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: _dangerColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load leave history',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No previous leave requests',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your leave request history will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequestModel leave) {
    final startDate =
        DateFormat('dd MMM yyyy').format(leave.startDate.toDate());
    final endDate = DateFormat('dd MMM yyyy').format(leave.endDate.toDate());

    // Determine color by status
    Color statusColor;
    IconData statusIcon;
    switch (leave.status.toLowerCase()) {
      case 'approved':
        statusColor = _successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = _dangerColor;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = _warningColor;
        statusIcon = Icons.access_time;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      leave.status,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  leave.leaveType,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Body with details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.date_range,
                  'Date',
                  startDate == endDate ? startDate : '$startDate to $endDate',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.schedule,
                  'Type',
                  leave.dayType,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.comment,
                  'Reason',
                  leave.reason,
                  isMultiLine: true,
                ),
                if (leave.approvedBy != null &&
                    leave.approvedBy!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person,
                    'Approved By',
                    leave.approvedBy!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isMultiLine = false}) {
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimaryColor,
                ),
                maxLines: isMultiLine ? null : 1,
                overflow: isMultiLine ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
