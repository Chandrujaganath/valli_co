// lib/widgets/follow_up_entry_widget.dart
import 'package:flutter/material.dart';

class FollowUpEntryWidget extends StatelessWidget {
  final TextEditingController followUpController;
  final VoidCallback onSave;

  const FollowUpEntryWidget({super.key, required this.followUpController, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: followUpController,
            decoration: InputDecoration(
              labelText: 'Follow-Up Details',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: onSave,
            child: Text('Save Follow-Up'),
          ),
        ],
      ),
    );
  }
}
