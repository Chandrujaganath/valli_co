// lib/screens/manager/customer_task_data_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/enquiry_service.dart';
import '../../models/enquiry_model.dart';

class CustomerTaskDataScreen extends StatelessWidget {
  const CustomerTaskDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enquiryService = Provider.of<EnquiryService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Customer & Task Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Enquiries & Follow-Ups',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<EnquiryModel>>(
                future: enquiryService.getEnquiries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error fetching enquiries.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No enquiries found.'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final enquiry = snapshot.data![index];
                        return ListTile(
                          title: Text(enquiry.enquiryName),
                          subtitle: Text('Follow-Up Status: ${enquiry.status}'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            // Navigate to enquiry details if needed
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
