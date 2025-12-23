import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import 'dashboard_screens.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _role = UserRole.student;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;

  //SEND OTP
  void _sendOtp() async {
    final response = await ApiService.sendOtpLogin(
      _phoneController.text,
      _role.name,
    );

    if (!response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['body']['message'])),
      );
      return;
    }

    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent')),
    );
  }

  // LOGIN
  void _login() async {
    final success = await ApiService.login(
      _phoneController.text,
      _otpController.text,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _role == UserRole.student
            ? const StudentDashboard()
            : _role == UserRole.merchant
                ? const MerchantDashboard(
                    merchantName: 'Merchant',
                    companyName: 'Company',
                  )
                : const AdminDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PAY - X')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_role.name} Login',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            ToggleButtons(
              isSelected: [
                _role == UserRole.student,
                _role == UserRole.merchant,
                _role == UserRole.admin,
              ],
              onPressed: (index) {
                setState(() {
                  _role = UserRole.values[index];
                  _otpSent = false;
                  _phoneController.clear();
                  _otpController.clear();
                });
              },
              children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('Student')),
                Padding(padding: EdgeInsets.all(8), child: Text('Merchant')),
                Padding(padding: EdgeInsets.all(8), child: Text('Admin')),
              ],
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            if (_otpSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _otpSent ? _login : _sendOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(_otpSent ? 'LOGIN' : 'SEND OTP'),
            ),

            const SizedBox(height: 8),

            if (_role != UserRole.admin)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegistrationScreen(userRole: _role),
                      ),
                    );
                  },
                  child: Text('New ${_role.name}? Register'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
