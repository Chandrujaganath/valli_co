// lib/screens/admin/logs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/log_service.dart';
import '../../models/log_model.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = Provider.of<LogService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Activity Logs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'User Activity Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<LogModel>>(
                future: logService.getLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error fetching logs.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No logs found.'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final log = snapshot.data![index];
                        return ListTile(
                          title: Text(log.userId),
                          subtitle: Text('Action: ${log.action} - Timestamp: ${log.timestamp.toDate()}'),
                          trailing: Icon(Icons.info_outline),
                          onTap: () {
                            // Show details of the log entry if needed
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
