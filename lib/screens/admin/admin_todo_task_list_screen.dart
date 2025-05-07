// lib/screens/admin/admin_todo_task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/todo_task_service.dart';
import '../../services/user_service.dart';
import '../../models/todo_task_model.dart';
import '../../models/user_model.dart';

class AdminTodoTaskListScreen extends StatefulWidget {
  const AdminTodoTaskListScreen({super.key});

  @override
  State<AdminTodoTaskListScreen> createState() =>
      _AdminTodoTaskListScreenState();
}

class _AdminTodoTaskListScreenState extends State<AdminTodoTaskListScreen> {
  String searchQuery = '';
  String filterStatus = 'All';
  List<String> statusOptions = [
    'All',
    'Assigned',
    'Accepted',
    'In Progress',
    'Completed'
  ];

  // For error handling in the StreamBuilder
  bool _hasError = false;
  String _errorMessage = '';

  // If we have a longer operation in progress (e.g. delete, mark completed),
  // we can show a loading overlay
  bool _isOperationInProgress = false;

  // Show an alert dialog with an error message
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _hasError = false;
                _errorMessage = '';
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // We can do any async operation here, e.g. deleting or updating a task
  Future<void> _performTaskAction({
    required TodoTaskModel task,
    required String confirmationTitle,
    required String confirmationMessage,
    required Function(TodoTaskModel) onConfirm,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(confirmationTitle),
          content: Text(confirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      setState(() => _isOperationInProgress = true);
      try {
        // Call the user-provided callback to actually perform the action
        await onConfirm(task);
      } catch (e) {
        if (!mounted) return;
        _showErrorDialog('Error performing operation: $e');
      } finally {
        if (mounted) {
          setState(() => _isOperationInProgress = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoTaskService =
        Provider.of<TodoTaskService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      // Premium AppBar gradient
      appBar: AppBar(
        title: const Text('All Todo Tasks'),
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
                colors: [Color(0xFFCFDEF3), Color(0xFFE0EAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Todo Task List',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),

                // Search and Filter
                Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Tasks',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Status Filter Dropdown
                    DropdownButton<String>(
                      value: filterStatus,
                      items: statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            filterStatus = value;
                          });
                        }
                      },
                      hint: const Text('Filter by Status'),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Todo Task List
                Expanded(
                  child: StreamBuilder<List<TodoTaskModel>>(
                    stream: todoTaskService.getAllTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        // Show an error dialog once
                        if (!_hasError) {
                          _hasError = true;
                          _errorMessage = snapshot.error.toString();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showErrorDialog(_errorMessage);
                          });
                        }
                        return const Center(
                          child: Text('Error retrieving todo tasks.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('No todo tasks found.'),
                        );
                      }

                      List<TodoTaskModel> tasks = snapshot.data!;

                      // Apply search filter
                      if (searchQuery.isNotEmpty) {
                        tasks = tasks.where((task) {
                          final lowerQ = searchQuery.toLowerCase();
                          return task.title.toLowerCase().contains(lowerQ) ||
                              task.description.toLowerCase().contains(lowerQ);
                        }).toList();
                      }

                      // Apply status filter
                      if (filterStatus != 'All') {
                        tasks = tasks
                            .where((task) => task.status == filterStatus)
                            .toList();
                      }

                      if (tasks.isEmpty) {
                        return const Center(
                          child: Text('No todo tasks found.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return FutureBuilder<UserModel?>(
                            future: userService.getUserById(task.assignedTo),
                            builder: (context, userSnapshot) {
                              String assignedToName = 'Loading...';
                              if (userSnapshot.connectionState ==
                                  ConnectionState.done) {
                                if (userSnapshot.hasError ||
                                    !userSnapshot.hasData) {
                                  assignedToName = 'Unavailable';
                                } else {
                                  assignedToName = userSnapshot.data!.name;
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 3,
                                child: ListTile(
                                  leading: getStatusIcon(task.status),
                                  title: Text(task.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Assigned To: $assignedToName'),
                                      Text('Status: ${task.status}'),
                                      Text(
                                        'Due Date: ${task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate!.toDate()) : 'N/A'}',
                                      ),
                                      const SizedBox(height: 4.0),
                                      // Progress Bar
                                      LinearProgressIndicator(
                                        value: task.percentageCompleted / 100,
                                        backgroundColor: Colors.grey[300],
                                        color: getProgressColor(
                                            task.percentageCompleted),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                          '${task.percentageCompleted}% Completed'),
                                    ],
                                  ),
                                  trailing: Text(
                                    DateFormat('yyyy-MM-dd')
                                        .format(task.createdAt.toDate()),
                                  ),
                                  isThreeLine: true,
                                  onTap: () => _showTaskDetails(task),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
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
    );
  }

  Icon getStatusIcon(String status) {
    switch (status) {
      case 'Assigned':
        return const Icon(Icons.assignment, color: Colors.blue);
      case 'Accepted':
        return const Icon(Icons.assignment_turned_in, color: Colors.orange);
      case 'In Progress':
        return const Icon(Icons.work, color: Colors.yellow);
      case 'Completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.help_outline);
    }
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

  void _showTaskDetails(TodoTaskModel task) async {
    final userService = Provider.of<UserService>(context, listen: false);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (ctx, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              task.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  // Description Section
                  Row(
                    children: const [
                      Icon(Icons.description, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text(
                        'Description:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(task.description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  // Assigned To Section
                  Row(
                    children: const [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Assigned To:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  FutureBuilder<UserModel?>(
                    future: userService.getUserById(task.assignedTo),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Unavailable',
                            style: TextStyle(fontSize: 16));
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${snapshot.data!.name} (${snapshot.data!.email})',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Assigned By Section
                  Row(
                    children: const [
                      Icon(Icons.person_outline, color: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text(
                        'Assigned By:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  FutureBuilder<UserModel?>(
                    future: userService.getUserById(task.assignedBy),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Unavailable',
                            style: TextStyle(fontSize: 16));
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${snapshot.data!.name} (${snapshot.data!.email})',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Status
                  Row(
                    children: const [
                      Icon(Icons.timelapse, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Status:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(task.status, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  // Progress
                  Row(
                    children: const [
                      Icon(Icons.percent, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Progress:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    '${task.percentageCompleted}% - '
                    '${task.progressDescription.isNotEmpty ? task.progressDescription : 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // Date Information
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Created At: '
                          '${DateFormat('yyyy-MM-dd').format(task.createdAt.toDate())}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Due Date: ${task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate!.toDate()) : 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: [
              // Example action: Mark as Completed
              // if (task.status != 'Completed')
              //   ElevatedButton.icon(
              //     onPressed: () {
              //       Navigator.pop(dialogContext); // Close detail dialog first
              //       _performTaskAction(
              //         task: task,
              //         confirmationTitle: 'Mark as Completed',
              //         confirmationMessage:
              //             'Are you sure you want to mark this task as Completed?',
              //         onConfirm: (t) async {
              //           // Implementation detail - call a method from your service
              //           final todoTaskService =
              //               Provider.of<TodoTaskService>(
              //             context,
              //             listen: false,
              //           );
              //           await todoTaskService.updateTaskStatus(
              //             t.taskId,
              //             'Completed',
              //             100,
              //             'Marked completed by Admin',
              //           );
              //         },
              //       );
              //     },
              //     style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              //     icon: const Icon(Icons.check),
              //     label: const Text('Mark Completed'),
              //   ),

              // Example action: Delete
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.pop(dialogContext); // Close detail dialog first
              //     _performTaskAction(
              //       task: task,
              //       confirmationTitle: 'Delete Task',
              //       confirmationMessage:
              //           'Are you sure you want to delete this task?',
              //       onConfirm: (t) async {
              //         final todoTaskService =
              //             Provider.of<TodoTaskService>(context, listen: false);
              //         await todoTaskService.deleteTask(t.taskId);
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(content: Text('Task deleted.')),
              //         );
              //       },
              //     );
              //   },
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              //   icon: const Icon(Icons.delete_forever),
              //   label: const Text('Delete'),
              // ),

              // TextButton(
              //   onPressed: () => Navigator.pop(dialogContext),
              //   child: const Text('Close', style: TextStyle(fontSize: 16)),
              // ),
            ],
          );
        });
      },
    );
  }
}
