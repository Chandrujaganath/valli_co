// lib/screens/common/user_todo_task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/todo_task_service.dart';
import '../../models/todo_task_model.dart';
import '../../providers/user_provider.dart';
import 'todo_task_detail_screen.dart';
import 'package:intl/intl.dart';

class UserTodoTaskListScreen extends StatefulWidget {
  const UserTodoTaskListScreen({super.key});

  @override
  State<UserTodoTaskListScreen> createState() =>
      _UserTodoTaskListScreenState();
}

class _UserTodoTaskListScreenState extends State<UserTodoTaskListScreen> {
  String searchQuery = '';
  String filterStatus = 'All';
  List<String> statusOptions = ['All', 'Assigned', 'Accepted', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final todoTaskService = Provider.of<TodoTaskService>(context, listen: false);
    final currentUser =
        Provider.of<UserProvider>(context, listen: false).user;

    if (currentUser == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Todo Tasks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'My Assigned Todo Tasks',
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
                stream: todoTaskService.getTasksByUserId(currentUser.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Error retrieving todo tasks.'));
                  }
                  List<TodoTaskModel> tasks = snapshot.data!;

                  // Apply search filter
                  if (searchQuery.isNotEmpty) {
                    tasks = tasks.where((task) =>
                        task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        task.description.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                  }

                  // Apply status filter
                  if (filterStatus != 'All') {
                    tasks = tasks.where((task) => task.status == filterStatus).toList();
                  }

                  if (tasks.isEmpty) {
                    return const Center(child: Text('No todo tasks found.'));
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        leading: getStatusIcon(task.status),
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${task.status}'),
                            Text('Due Date: ${task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate!.toDate()) : 'N/A'}'),
                            const SizedBox(height: 4.0),
                            // Progress Bar
                            LinearProgressIndicator(
                              value: task.percentageCompleted / 100,
                              backgroundColor: Colors.grey[300],
                              color: getProgressColor(task.percentageCompleted),
                            ),
                            const SizedBox(height: 4.0),
                            Text('${task.percentageCompleted}% Completed'),
                          ],
                        ),
                        trailing: Text(DateFormat('yyyy-MM-dd').format(task.createdAt.toDate())),
                        isThreeLine: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodoTaskDetailScreen(task: task),
                          ),
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
}
