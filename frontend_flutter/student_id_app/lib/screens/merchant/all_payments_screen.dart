import 'package:flutter/material.dart';

class AllPaymentsScreen extends StatelessWidget {
  const AllPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Payments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Student Canteen'),
            trailing: Text('₹120'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Book Store'),
            trailing: Text('₹350'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Library Fee'),
            trailing: Text('₹80'),
          ),
        ],
      ),
    );
  }
}
