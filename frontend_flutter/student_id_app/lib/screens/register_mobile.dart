import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_otp.dart';

class RegisterMobile extends StatelessWidget {
  final TextEditingController mobileController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: mobileController,
              decoration: InputDecoration(labelText: "Mobile Number"),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool sent = await ApiService.sendRegisterOtp(
                    mobileController.text);
                if (sent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterOtp(
                        mobile: mobileController.text,
                      ),
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
