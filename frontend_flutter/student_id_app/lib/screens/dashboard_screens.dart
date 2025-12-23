import 'package:flutter/material.dart';
import 'login_screen.dart';

/// ================= STUDENT DASHBOARD =================
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // ❌ Disable back button
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          backgroundColor: const Color(0xFF4361EE),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Welcome Student!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= MERCHANT DASHBOARD =================
class MerchantDashboard extends StatelessWidget {
  final String merchantName;
  final String companyName;

  const MerchantDashboard({
    super.key,
    required this.merchantName,
    required this.companyName,
  });

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Merchant Dashboard'),
          backgroundColor: Colors.green,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.store, size: 70),
              const SizedBox(height: 10),
              Text(
                'Welcome $merchantName',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text('Company: $companyName'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= ADMIN DASHBOARD =================
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Welcome Admin!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
