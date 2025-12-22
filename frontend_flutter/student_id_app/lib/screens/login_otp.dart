import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard.dart';

class LoginOtp extends StatelessWidget {
  final String mobile;
  LoginOtp({required this.mobile});

  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              decoration: InputDecoration(labelText: "OTP"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool success =
                    await ApiService.verifyLoginOtp(mobile, otpController.text);

                if (success) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

