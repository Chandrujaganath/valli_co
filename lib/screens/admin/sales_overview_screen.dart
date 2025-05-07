// lib/screens/admin/sales_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sales_service.dart';
import '../../models/sales_model.dart';

class SalesOverviewScreen extends StatelessWidget {
  const SalesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesService = Provider.of<SalesService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Sales Overview')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total Sales Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<SalesModel>>(
                future: salesService.getSales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error fetching sales data.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No sales data found.'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final sale = snapshot.data![index];
                        return ListTile(
                          title: Text(sale.productsSold as String),
                          subtitle: Text('Amount: \$${sale.crAmount} - Status: ${sale.salesStatus}'),
                          trailing: Text(sale.salesStatus),
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
