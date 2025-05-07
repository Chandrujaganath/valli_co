import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/organisation_service.dart';
import '../../models/branch_model.dart';

class OrganisationManagementScreen extends StatefulWidget {
  const OrganisationManagementScreen({super.key});

  @override
  State<OrganisationManagementScreen> createState() =>
      _OrganisationManagementScreenState();
}

class _OrganisationManagementScreenState
    extends State<OrganisationManagementScreen> {
  // For showing a loading overlay when we perform add/update/delete
  bool _isOperationInProgress = false;

  /// Open the Branch form. If [branch] is null, we're adding a new branch.
  /// If [branch] is not null, we're editing the existing branch.
  void _openBranchForm([BranchModel? branch]) {
    showDialog(
      context: context,
      builder: (ctx) => BranchFormDialog(
        branch: branch,
        onSave: (branchModel) async {
          // Ask user "Are you sure?" before final save
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (innerCtx) {
              return AlertDialog(
                title: const Text('Confirm Save'),
                content: Text(branch == null
                    ? 'Are you sure you want to add this new branch?'
                    : 'Are you sure you want to update the branch "${branch.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(innerCtx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(innerCtx, true),
                    child: const Text('Yes'),
                  ),
                ],
              );
            },
          );

          if (confirmed != true) return; // user cancelled

          setState(() => _isOperationInProgress = true);
          final organisationService =
              Provider.of<OrganisationService>(context, listen: false);

          try {
            if (branchModel.branchId.isEmpty) {
              // Add new
              await organisationService.addBranch(branchModel);
            } else {
              // Update existing
              await organisationService.updateBranch(
                branchModel.branchId,
                branchModel.toJson(),
              );
            }
            // After success, we refresh the list
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  branch == null
                      ? 'Branch added successfully!'
                      : 'Branch updated successfully!',
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          } finally {
            setState(() => _isOperationInProgress = false);
          }
        },
      ),
    );
  }

  /// Confirm and delete a branch
  Future<void> _deleteBranch(BranchModel branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete branch "${branch.name}"?'),
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
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isOperationInProgress = true);
    final orgService = Provider.of<OrganisationService>(context, listen: false);
    try {
      await orgService.deleteBranch(branch.branchId);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting branch: $e')),
      );
    } finally {
      setState(() => _isOperationInProgress = false);
    }
  }

  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat.jm().format(dt); // "6:00 AM"
  }

  @override
  Widget build(BuildContext context) {
    final organisationService = Provider.of<OrganisationService>(context, listen: false);

    return Scaffold(
      // Premium app bar with gradient
      appBar: AppBar(
        title: const Text('Organisation Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // Premium gradient behind body
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], // soft gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // The main content: FutureBuilder for branches
          FutureBuilder<List<BranchModel>>(
            future: organisationService.getBranches(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching branches.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final data = snapshot.data;
              if (data == null || data.isEmpty) {
                return const Center(child: Text('No branches found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                itemBuilder: (ctx, index) {
                  final branch = data[index];
                  final clockInTime = _formatTime(branch.clockInMinutes);
                  final bufferTime = branch.bufferMinutes;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        branch.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${branch.address}\nClock In: $clockInTime, Buffer: $bufferTime mins',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openBranchForm(branch),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBranch(branch),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isOperationInProgress)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBranchForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// A separate dialog for adding/editing a branch
class BranchFormDialog extends StatefulWidget {
  final BranchModel? branch;
  final Future<void> Function(BranchModel) onSave;

  const BranchFormDialog({
    Key? key,
    this.branch,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  TimeOfDay _clockInTime = const TimeOfDay(hour: 9, minute: 0);
  final _bufferMinutesController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _nameController.text = widget.branch!.name;
      _addressController.text = widget.branch!.address;
      _clockInTime = TimeOfDay(
        hour: widget.branch!.clockInMinutes ~/ 60,
        minute: widget.branch!.clockInMinutes % 60,
      );
      _bufferMinutesController.text = widget.branch!.bufferMinutes.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _bufferMinutesController.dispose();
    super.dispose();
  }

  Future<void> _selectClockInTime(BuildContext ctx) async {
    final picked = await showTimePicker(
      context: ctx,
      initialTime: _clockInTime,
    );
    if (picked != null && picked != _clockInTime) {
      setState(() => _clockInTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branch != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Branch' : 'Add Branch'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Branch Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter branch name' : null,
              ),
              const SizedBox(height: 12),
              // Branch Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Branch Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 12),
              // Clock In Time
              Row(
                children: [
                  Expanded(
                    child: Text('Clock In: ${_clockInTime.format(context)}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selectClockInTime(context),
                  )
                ],
              ),
              const SizedBox(height: 12),
              // Buffer Time
              TextFormField(
                controller: _bufferMinutesController,
                decoration: const InputDecoration(
                  labelText: 'Buffer Time (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter buffer time';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final clockInMinutes = _clockInTime.hour * 60 + _clockInTime.minute;
              final buffer = int.parse(_bufferMinutesController.text.trim());
              final newBranch = BranchModel(
                branchId: widget.branch?.branchId ?? '',
                name: _nameController.text.trim(),
                address: _addressController.text.trim(),
                clockInMinutes: clockInMinutes,
                bufferMinutes: buffer,
              );

              await widget.onSave(newBranch);

              // If we get here, the save is presumably done; close dialog
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
