// lib/screens/manager/team_performance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/performance_service.dart';
import '../../models/performance_model.dart';

class TeamPerformanceScreen extends StatelessWidget {
  const TeamPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final performanceService = Provider.of<PerformanceService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Team Performance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Performance Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<PerformanceModel>>(
                future: performanceService.getTeamPerformance(), // Corrected method name
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error fetching performance data.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No performance data available.'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final performance = snapshot.data![index];
                        return ListTile(
                          title: Text(performance.staffName),
                          subtitle: Text(
                            'Tasks Completed: ${performance.tasksCompleted} - Pending: ${performance.tasksPending}',
                          ),
                          trailing: Icon(Icons.bar_chart),
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
