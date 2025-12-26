import 'package:flutter/material.dart';

class ReportsAnalyticsScreen extends StatelessWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('Daily Transactions'),
                trailing: Text('1,245'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.trending_up),
                title: Text('Monthly Revenue'),
                trailing: Text('₹4,50,000'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Active Users'),
                trailing: Text('3,120'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
