// lib/screens/admin/admin_todo_task_history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/todo_task_service.dart';
import '../../models/todo_task_model.dart';

class AdminTodoTaskHistoryScreen extends StatefulWidget {
  const AdminTodoTaskHistoryScreen({super.key});

  @override
  State<AdminTodoTaskHistoryScreen> createState() =>
      _AdminTodoTaskHistoryScreenState();
}

class _AdminTodoTaskHistoryScreenState
    extends State<AdminTodoTaskHistoryScreen> {
  String searchQuery = '';
  String sortBy = 'createdAt';
  bool descending = true;

  // Whether an error has occurred, and we’re showing a retry approach
  bool _hasError = false;
  String _errorMessage = '';

  /// Shows an alert dialog with an error message.
  void _showErrorDialog(BuildContext context, String message) {
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

  @override
  Widget build(BuildContext context) {
    final todoTaskService =
        Provider.of<TodoTaskService>(context, listen: false);

    return Scaffold(
      // Premium gradient AppBar
      appBar: AppBar(
        title: const Text('Completed Todo Task History'),
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
          // Nice gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFCFDEF3),
                  Color(0xFFE0EAFC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search & sort options
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Completed Tasks',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: sortBy,
                      items: const [
                        DropdownMenuItem(
                          value: 'createdAt',
                          child: Text('Created Date'),
                        ),
                        DropdownMenuItem(
                          value: 'title',
                          child: Text('Title'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            sortBy = value;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        descending ? Icons.arrow_downward : Icons.arrow_upward,
                      ),
                      onPressed: () {
                        setState(() {
                          descending = !descending;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // List of completed tasks (filter by status == Completed)
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
                        // Show an error dialog
                        if (!_hasError) {
                          _hasError = true;
                          _errorMessage = snapshot.error.toString();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _showErrorDialog(context, _errorMessage);
                          });
                        }
                        return const Center(
                          child: Text('Error retrieving tasks.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('No data available.'),
                        );
                      }

                      List<TodoTaskModel> tasks = snapshot.data!;
                      // Only completed tasks
                      tasks = tasks
                          .where((task) => task.status == 'Completed')
                          .toList();
                      if (searchQuery.isNotEmpty) {
                        tasks = tasks.where((task) {
                          final q = searchQuery.toLowerCase();
                          return task.title.toLowerCase().contains(q) ||
                              task.description.toLowerCase().contains(q);
                        }).toList();
                      }

                      // Sorting
                      tasks.sort((a, b) {
                        int cmp;
                        if (sortBy == 'createdAt') {
                          cmp = a.createdAt.compareTo(b.createdAt);
                        } else {
                          cmp = a.title.compareTo(b.title);
                        }
                        return descending ? -cmp : cmp;
                      });

                      if (tasks.isEmpty) {
                        return const Center(
                          child: Text('No completed tasks found.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Description: ${task.description}'),
                                    Text(
                                      'Completed on: '
                                      '${DateFormat('yyyy-MM-dd').format(task.updatedAt.toDate())}',
                                    ),
                                    if (task.updateHistory != null &&
                                        task.updateHistory!.isNotEmpty)
                                      Text(
                                        'Updates: '
                                        '${task.updateHistory!.length}',
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                DateFormat('yyyy-MM-dd')
                                    .format(task.createdAt.toDate()),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                // Show a detailed view with update history
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        _CompletedTaskDetailScreen(task: task),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A screen showing details of one completed task.
class _CompletedTaskDetailScreen extends StatelessWidget {
  final TodoTaskModel task;

  const _CompletedTaskDetailScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    // Detailed view including update history
    return Scaffold(
      appBar: AppBar(
        title: Text('Task History: ${task.title}'),
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
                colors: [Color(0xFFF5F7FA), Color(0xFFE4EBF5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description: ${task.description}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${task.status}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Due Date: ${task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate!.toDate()) : 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created At: '
                      '${DateFormat('yyyy-MM-dd').format(task.createdAt.toDate())}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Update History:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    if (task.updateHistory == null ||
                        task.updateHistory!.isEmpty)
                      const Text('No updates recorded.'),
                    if (task.updateHistory != null)
                      ...task.updateHistory!.map((update) {
                        final ts = update['updatedAt'] as Timestamp?;
                        final updatedAtStr = ts != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate())
                            : '--';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(update['status'] ?? ''),
                            subtitle: Text(
                              'Progress: ${update['percentageCompleted'] ?? 0}%\n'
                              '${update['progressDescription'] ?? ''}',
                            ),
                            trailing: Text(updatedAtStr),
                          ),
                        );
                      }).toList(),

                    // Example: A destructive button that might require confirmation
                    // for archiving or permanently removing the task from history
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Archive Task'),
                              content: const Text(
                                'Are you sure you want to archive/remove this completed task?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Archive'),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          // TODO: Implement your archive/delete logic here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task archived (not implemented).'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.archive),
                      label: const Text('Archive Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
