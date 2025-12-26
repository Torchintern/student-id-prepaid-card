import 'package:flutter/material.dart';

class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.school),
              title: Text('Rahul Kumar'),
              subtitle: Text('rahul@gmail.com'),
              trailing: Icon(Icons.block, color: Colors.red),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.school),
              title: Text('Ananya Sharma'),
              subtitle: Text('ananya@gmail.com'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.school),
              title: Text('Vivek Reddy'),
              subtitle: Text('vivek@gmail.com'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
