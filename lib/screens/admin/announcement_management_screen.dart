// lib/screens/admin/announcement_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/announcement_provider.dart';

class AnnouncementManagementScreen extends StatelessWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final announcementProvider = Provider.of<AnnouncementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show a dialog to add an announcement
          await showDialog(
            context: context,
            builder: (_) => const _AnnouncementDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: announcementProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: announcementProvider.announcements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final announcement = announcementProvider.announcements[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      announcement.title,
                      style: TextStyle(
                        fontWeight: announcement.pinned
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: announcement.pinned ? Colors.redAccent : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        announcement.message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.redAccent,
                      onPressed: () async {
                        try {
                          await announcementProvider.removeAnnouncement(
                              announcement.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement deleted')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting announcement: $e')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog();

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isPinned = false;
  final List<String> _allRoles = ['all', 'admin', 'manager', 'sales', 'measurement'];
  final List<String> _selectedRoles = ['all']; // Default to all
  bool _isProcessing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Announcement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text("Pin this announcement"),
              value: _isPinned,
              onChanged: (val) {
                setState(() {
                  _isPinned = val ?? false;
                });
              },
            ),
            const SizedBox(height: 12),
            const Text('Select Target Roles:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _allRoles.map((role) {
                final selected = _selectedRoles.contains(role);
                return FilterChip(
                  label: Text(role.toUpperCase()),
                  selected: selected,
                  onSelected: (bool value) {
                    setState(() {
                      if (value) {
                        if (role == 'all') {
                          _selectedRoles.clear();
                          _selectedRoles.add('all');
                        } else {
                          _selectedRoles.remove('all');
                          _selectedRoles.add(role);
                        }
                      } else {
                        _selectedRoles.remove(role);
                        if (_selectedRoles.isEmpty) {
                          _selectedRoles.add('all');
                        }
                      }
                    });
                  },
                );
              }).toList(),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  if (_titleController.text.trim().isEmpty ||
                      _messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields.')),
                    );
                    return;
                  }
                  setState(() {
                    _isProcessing = true;
                  });
                  final provider =
                      Provider.of<AnnouncementProvider>(context, listen: false);
                  try {
                    await provider.addAnnouncement(
                      _titleController.text.trim(),
                      _messageController.text.trim(),
                      _isPinned,
                      _selectedRoles,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Announcement added successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding announcement: $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  }
                },
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
