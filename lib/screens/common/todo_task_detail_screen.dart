// lib/screens/user/todo_task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/todo_task_service.dart';
import '../../models/todo_task_model.dart';

class TodoTaskDetailScreen extends StatefulWidget {
  final TodoTaskModel task;

  const TodoTaskDetailScreen({required this.task, super.key});

  @override
  State<TodoTaskDetailScreen> createState() => _TodoTaskDetailScreenState();
}

class _TodoTaskDetailScreenState extends State<TodoTaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedStatus = '';
  int percentageCompleted = 0;
  String progressDescription = '';
  bool _isUpdating = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the current task values.
    selectedStatus = widget.task.status;
    percentageCompleted = widget.task.percentageCompleted;
    progressDescription = widget.task.progressDescription;
  }

  /// Called when the user taps "Accept Task". Updates the task status to "Accepted".
  void _acceptTask() async {
    setState(() {
      _isAccepting = true;
    });
    final todoTaskService =
        Provider.of<TodoTaskService>(context, listen: false);
    try {
      await todoTaskService.updateTaskStatusAndProgress(
          widget.task.taskId, 'Accepted', 0, '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task accepted successfully')),
      );
      setState(() {
        selectedStatus = 'Accepted';
        percentageCompleted = 0;
        progressDescription = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting task: $e')),
      );
    } finally {
      setState(() {
        _isAccepting = false;
      });
    }
  }

  /// Called when updating progress. This is only enabled when the selected status is "In Progress".
  void _updateProgress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });
      final todoTaskService =
          Provider.of<TodoTaskService>(context, listen: false);
      try {
        await todoTaskService.updateTaskStatusAndProgress(
            widget.task.taskId, selectedStatus, percentageCompleted, progressDescription);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      } finally {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  /// Returns true only if progress updates are allowed – that is, the task is not "Assigned" or "Completed"
  /// and the selected status is "In Progress".
  bool get _canUpdateProgress {
    return widget.task.status != 'Assigned' &&
        selectedStatus == 'In Progress';
  }

  /// Returns the allowed dropdown options based on the current selectedStatus.
  /// - If the current status is "Accepted", options: ["Accepted", "In Progress"]  
  /// - If already "In Progress", options: ["In Progress", "Completed"]  
  /// - If "Completed", only ["Completed"] is allowed.
  List<String> getAllowedStatusOptions() {
    if (widget.task.status == 'Assigned') {
      return []; // The form isn’t shown in this state.
    } else if (selectedStatus == 'Accepted') {
      return ['Accepted', 'In Progress'];
    } else if (selectedStatus == 'In Progress') {
      return ['In Progress', 'Completed'];
    } else if (selectedStatus == 'Completed') {
      return ['Completed'];
    } else {
      return ['Accepted', 'In Progress', 'Completed'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTaskAccepted = widget.task.status != 'Assigned';
    final isTaskCompleted = widget.task.status == 'Completed';

    return Scaffold(
      appBar: AppBar(title: const Text('Todo Task Details')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.task.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                Text(widget.task.description),
                const SizedBox(height: 16.0),
                Text('Current Status: ${widget.task.status}'),
                const SizedBox(height: 16.0),
                LinearProgressIndicator(
                  value: widget.task.percentageCompleted / 100,
                  backgroundColor: Colors.grey[300],
                  color: getProgressColor(widget.task.percentageCompleted),
                ),
                const SizedBox(height: 4.0),
                Text('${widget.task.percentageCompleted}% Completed'),
                const SizedBox(height: 16.0),
                if (!isTaskAccepted)
                  ElevatedButton(
                    onPressed: _acceptTask,
                    child: const Text('Accept Task'),
                  ),
                if (isTaskAccepted && !isTaskCompleted)
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Dropdown for status update with restricted options.
                            DropdownButtonFormField<String>(
                              value: selectedStatus,
                              items: getAllowedStatusOptions().map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedStatus = value;
                                    if (selectedStatus == 'Completed') {
                                      percentageCompleted = 100;
                                    }
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Update Status',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Please select a status' : null,
                            ),
                            const SizedBox(height: 16.0),
                            if (_canUpdateProgress) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Percentage Completed',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Slider(
                                    value: percentageCompleted.toDouble(),
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: '$percentageCompleted%',
                                    onChanged: (double value) {
                                      setState(() {
                                        percentageCompleted = value.toInt();
                                      });
                                    },
                                  ),
                                  Text('$percentageCompleted%'),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                initialValue: progressDescription,
                                decoration: const InputDecoration(
                                  labelText: 'Progress Description',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  setState(() {
                                    progressDescription = value;
                                  });
                                },
                                validator: (value) {
                                  if (selectedStatus == 'In Progress') {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter progress description';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: _updateProgress,
                                child: const Text('Update Progress'),
                              ),
                            ],
                            if (selectedStatus == 'Accepted')
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Once set to In Progress, you cannot revert back to Accepted. '
                                  'Select In Progress to continue, then Completed when done.',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isTaskCompleted)
                  const Text(
                    'This task has been completed and cannot be updated further.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          if (_isUpdating || _isAccepting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Color getProgressColor(int percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.lightGreen;
    } else if (percentage >= 25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
