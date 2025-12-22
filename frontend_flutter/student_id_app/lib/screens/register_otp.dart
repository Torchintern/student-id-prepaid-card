import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterOtp extends StatelessWidget {
  final String mobile;
  RegisterOtp({required this.mobile});

  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: otpController,
              decoration: InputDecoration(labelText: "OTP"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool success = await ApiService.verifyRegisterOtp(
                    nameController.text, mobile, otpController.text, "student");

                if (success) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: Text("Verify & Register"),
            ),
          ],
        ),
      ),
    );
  }
}
