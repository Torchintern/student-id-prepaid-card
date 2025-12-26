import 'package:flutter/material.dart';

class BusinessInsightsScreen extends StatelessWidget {
  const BusinessInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Insights')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.trending_up),
                title: Text('Today Sales'),
                trailing: Text('₹2,580'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('Monthly Revenue'),
                trailing: Text('₹45,000'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
