// lib/screens/admin/user_management_screen.dart

// ignore_for_file: unused_field, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'user_form_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late UserService userService;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    userService = Provider.of<UserService>(context, listen: false);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    _users = await userService.getUsers();
    setState(() {
      _filteredUsers = _users;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredUsers = _users
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.role.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _openUserForm({UserModel? user}) async {
  bool? result = await showDialog(
    context: context,
    builder: (context) => UserFormDialog(
      user: user,
    ),
  );

  if (result == true) {
    _loadUsers();
  }
}


  void _deleteUser(UserModel user) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${user.name}?'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm) {
      await userService.deleteUser(user.userId);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _buildUserList(currentUserId),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openUserForm(),
          child: const Icon(Icons.add),
        ));
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Search Users',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: _filterUsers,
    );
  }

  Widget _buildUserList(String? currentUserId) {
    if (_filteredUsers.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.separated(
      itemCount: _filteredUsers.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(user.name.substring(0, 1).toUpperCase()),
          ),
          title: Text(user.name),
          subtitle: Text('${user.role} - ${user.isActive ? 'Active' : 'Inactive'}'),
          trailing: user.userId != currentUserId
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openUserForm(user: user);
                    } else if (value == 'delete') {
                      _deleteUser(user);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                )
              : null,
          onTap: () {
            if (user.userId != currentUserId) {
              _openUserForm(user: user);
            }
          },
        );
      },
    );
  }
}
