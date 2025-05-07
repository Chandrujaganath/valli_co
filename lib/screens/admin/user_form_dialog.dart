// lib/screens/admin/user_form_dialog.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/organisation_service.dart';
import '../../models/branch_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFormDialog extends StatefulWidget {
  final UserModel? user;

  const UserFormDialog({super.key, this.user});

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late UserService userService;
  late OrganisationService organisationService;
  bool _isSaving = false;


  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'Sales Staff';
  bool _isActive = true;
  DateTime? _dob;
  DateTime? _joiningDate;
  String? _branchId;
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    userService = Provider.of<UserService>(context, listen: false);
    organisationService = Provider.of<OrganisationService>(context, listen: false);
    _loadBranches();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _mobileController.text = widget.user!.mobileNumber;
      _addressController.text = widget.user!.address;
      _role = widget.user!.role;
      _isActive = widget.user!.isActive;
      _dob = widget.user!.dob.toDate();
      _joiningDate = widget.user!.joiningDate.toDate();
      _branchId = widget.user!.branchId;
    }
  }

  Future<void> _loadBranches() async {
    _branches = await organisationService.getBranches();
    if (_branchId == null && _branches.isNotEmpty) {
      _branchId = _branches.first.branchId;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
  if (_isSaving) return; // Prevent multiple clicks
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isSaving = true;
  });

  UserModel user = UserModel(
    userId: widget.user?.userId ?? '',
    name: _nameController.text.trim(),
    email: _emailController.text.trim(),
    mobileNumber: _mobileController.text.trim(),
    address: _addressController.text.trim(),
    role: _role,
    isActive: _isActive,
    dob: Timestamp.fromDate(_dob ?? DateTime.now()),
    joiningDate: Timestamp.fromDate(_joiningDate ?? DateTime.now()),
    branchId: _branchId ?? '',
    profilePhotoUrl: '',
  );

  try {
    if (widget.user == null) {
      // Adding new user
      await userService.addUser(user, _passwordController.text.trim());

      // Close the dialog and refresh the user list
      Navigator.pop(context, true);
    } else {
      // Updating existing user
      await userService.updateUser(user);
      Navigator.pop(context, true);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving user: $e')),
    ); // ... error handling ...
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}


  Widget _buildDropdown<T>({
    required String label,
    T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        DateTime initialDate = selectedDate ?? DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(selectedDate != null
            ? '${selectedDate.toLocal()}'.split(' ')[0]
            : 'Select Date'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              // Password (only for new users)
              if (widget.user == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter password' : null,
                ),
              if (widget.user == null)
                const SizedBox(height: 16),
              // Mobile Number
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter mobile number';
                  if (value.length != 10) return 'Mobile number must be 10 digits';
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Invalid mobile number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Role
              _buildDropdown<String>(
                label: 'Role *',
                value: _role,
                items: ['Admin', 'Manager', 'Sales Staff', 'Measurement Staff'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: 16),
              // Branch
              _buildDropdown<String>(
                label: 'Branch *',
                value: _branchId,
                items: _branches.map((branch) {
                  return DropdownMenuItem(value: branch.branchId, child: Text(branch.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _branchId = value);
                },
              ),
              const SizedBox(height: 16),
              // Active Status
              SwitchListTile(
                title: const Text('Active Status'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 16),
              // DOB
              _buildDatePicker(
                label: 'Date of Birth',
                selectedDate: _dob,
                onChanged: (date) => setState(() => _dob = date),
              ),
              const SizedBox(height: 16),
              // Joining Date
              _buildDatePicker(
                label: 'Joining Date',
                selectedDate: _joiningDate,
                onChanged: (date) => setState(() => _joiningDate = date),
              ),
              const SizedBox(height: 16),
              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // Save Button
              SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _isSaving ? null : _saveUser,
    child: _isSaving
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Text('Save'),
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}
