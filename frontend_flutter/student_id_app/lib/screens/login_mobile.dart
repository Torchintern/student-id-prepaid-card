import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_otp.dart';
import 'register_mobile.dart';

class LoginMobile extends StatelessWidget {
  final TextEditingController mobileController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: mobileController,
              decoration: InputDecoration(labelText: "Mobile Number"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool sent =
                    await ApiService.sendLoginOtp(mobileController.text);
                if (sent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginOtp(mobile: mobileController.text),
                    ),
                  );
                }
              },
              child: Text("Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
