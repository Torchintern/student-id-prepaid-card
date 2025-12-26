import 'package:flutter/material.dart';

class MerchantManagementScreen extends StatelessWidget {
  const MerchantManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.store),
              title: Text('Campus Canteen'),
              subtitle: Text('Food Services'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.store),
              title: Text('Book World'),
              subtitle: Text('Retail Store'),
              trailing: Icon(Icons.block, color: Colors.red),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.store),
              title: Text('Stationery Hub'),
              subtitle: Text('Retail Store'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
