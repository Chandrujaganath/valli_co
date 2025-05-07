import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../services/todo_task_service.dart';
import '../../services/user_service.dart';
import '../../models/todo_task_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class AdminTodoTaskAssignmentScreen extends StatefulWidget {
  const AdminTodoTaskAssignmentScreen({super.key});

  @override
  State<AdminTodoTaskAssignmentScreen> createState() =>
      _AdminTodoTaskAssignmentScreenState();
}

class _AdminTodoTaskAssignmentScreenState
    extends State<AdminTodoTaskAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _dueDate;
  UserModel? _selectedUser;

  // Loading indicators
  bool _isFetchingUsers = true; // for fetching user list
  bool _isOperationInProgress = false; // for assigning the task

  // Track original state for "discard changes" prompt
  bool _hasUnsavedData = false;

  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    // Listen for text changes to track unsaved data
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // If either field has text or we have a selected user/due date, consider it unsaved data
    if (_titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _selectedUser != null ||
        _dueDate != null) {
      if (!_hasUnsavedData) {
        setState(() {
          _hasUnsavedData = true;
        });
      }
    } else {
      if (_hasUnsavedData) {
        setState(() {
          _hasUnsavedData = false;
        });
      }
    }
  }

  /// Fetch users with roles 'Sales Staff', 'Measurement Staff', 'Manager'.
  Future<void> _fetchUsers() async {
    final userService = Provider.of<UserService>(context, listen: false);
    try {
      final fetchedUsers = await userService.getUsersByRoles([
        'Sales Staff',
        'Measurement Staff',
        'Manager',
      ]);
      if (!mounted) return;
      setState(() {
        _users = fetchedUsers;
        _isFetchingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingUsers = false);
      _showErrorDialog('Error fetching users: $e');
    }
  }

  /// Show a premium-styled error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog before assigning the task
  void _confirmAssignment() {
    if (!_formKey.currentState!.validate()) {
      return; // form not valid
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Assignment'),
          content: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
              children: [
                const TextSpan(
                    text: 'Are you sure you want to assign this task to '),
                TextSpan(
                  text: '"${_selectedUser?.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' with a due date of '),
                TextSpan(
                  text: _dueDate != null
                      ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                      : '---',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        _assignTodoTask();
      }
    });
  }

  /// Actually assigns the new task
  Future<void> _assignTodoTask() async {
    final todoTaskService =
        Provider.of<TodoTaskService>(context, listen: false);
    final currentAdmin = Provider.of<UserProvider>(context, listen: false).user;
    setState(() => _isOperationInProgress = true);

    try {
      final taskId = const Uuid().v4();
      final newTask = TodoTaskModel(
        taskId: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: _selectedUser!.userId,
        assignedBy: currentAdmin?.userId ?? 'admin_default',
        status: 'Assigned',
        percentageCompleted: 0,
        progressDescription: '',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(_dueDate!),
      );

      await todoTaskService.assignTodoTask(newTask);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todo task assigned successfully!')),
      );

      // Clear fields
      _formKey.currentState!.reset();
      setState(() {
        _selectedUser = null;
        _dueDate = null;
        _titleController.clear();
        _descriptionController.clear();
        _hasUnsavedData = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error assigning todo task: $e');
    } finally {
      if (mounted) {
        setState(() => _isOperationInProgress = false);
      }
    }
  }

  /// Prompt user if they try to go back with unsaved changes
  Future<bool> _onWillPop() async {
    if (_hasUnsavedData) {
      // Show confirm discard dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
                'You have entered data that has not been assigned yet. '
                'Are you sure you want to leave and discard your changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          );
        },
      );
      return confirm ?? false;
    }
    // If no unsaved data or user confirmed discard, allow pop
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Premium top app bar with gradient
        appBar: AppBar(
          title: const Text('Assign Todo Task'),
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
        body: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE0EAFC),
                    Color(0xFFCFDEF3)
                  ], // lighter gradient
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // The main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isFetchingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _buildForm(context),
            ),
            if (_isOperationInProgress)
              // A semi-transparent overlay with a progress indicator
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found to assign tasks.'),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Assign a Todo Task to a User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),

                // User Autocomplete
                _buildUserAutocomplete(),
                const SizedBox(height: 16.0),

                // Task Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter the task title'
                      : null,
                ),
                const SizedBox(height: 16.0),

                // Task Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter the task description'
                      : null,
                ),
                const SizedBox(height: 16.0),

                // Due Date
                _buildDueDateField(),
                const SizedBox(height: 16.0),

                // Assign Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmAssignment,
                  child: const Text('Assign Todo Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAutocomplete() {
    return Autocomplete<UserModel>(
      displayStringForOption: (UserModel option) => option.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<UserModel>.empty();
        }
        return _users
            .where((UserModel user) => user.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()))
            .take(10);
      },
      onSelected: (UserModel selection) {
        setState(() {
          _selectedUser = selection;
          _onFieldChanged();
        });
      },
      fieldViewBuilder:
          (context, textController, focusNode, onEditingComplete) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Assign To *',
            border: const OutlineInputBorder(),
            suffixIcon: _selectedUser != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textController.clear();
                      setState(() {
                        _selectedUser = null;
                        _onFieldChanged();
                      });
                    },
                  )
                : null,
          ),
          validator: (value) {
            if (_selectedUser == null) {
              return 'Please select a user to assign the task';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDueDateField() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: _dueDate != null
            ? 'Due Date: ${DateFormat('yyyy-MM-dd').format(_dueDate!)} *'
            : 'Select Due Date *',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final now = DateTime.now();
        try {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dueDate ?? now,
            firstDate: now, // Prevent selecting past dates
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _dueDate = picked;
              _onFieldChanged();
            });
          }
        } catch (e) {
          _showErrorDialog('Error picking due date: $e');
        }
      },
      validator: (value) =>
          _dueDate == null ? 'Please select a due date' : null,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
