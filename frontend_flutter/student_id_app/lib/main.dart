import 'package:flutter/material.dart';

import 'screens/login_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 👇 Initial screen
      initialRoute: '/login',

      // 👇 Named routes
      routes: {
        '/login': (context) => const LoginScreen(),
        
      },
    );
  }
}
