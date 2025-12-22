import 'package:flutter/material.dart';
import 'screens/login_mobile.dart';
import 'screens/register_mobile.dart';
import 'screens/dashboard.dart';


void main() {
  runApp(StudentIDApp());
}

class StudentIDApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student ID Prepaid Card',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // Initial screen
      initialRoute: '/',

      // App routes
      routes: {
  '/': (context) => LoginMobile(),
  '/register': (context) => RegisterMobile(),
  '/dashboard': (context) => DashboardPage(),
},

    );
  }
}
