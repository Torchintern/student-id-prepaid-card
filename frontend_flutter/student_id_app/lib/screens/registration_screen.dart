import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  final UserRole userRole;
  const RegistrationScreen({super.key, required this.userRole});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  final _name = TextEditingController();
  final _college = TextEditingController();
  final _company = TextEditingController();
  final _tax = TextEditingController();

  bool _otpSent = false;
  bool _verified = false;

  void _sendOtp() async {
    final response =
        await ApiService.sendOtpRegister(_phone.text);

    if (!response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['body']['message'])),
      );
      return;
    }

    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('OTP sent')));
  }

  void _verifyOtp() async {
    final success =
        await ApiService.verifyOtp(_phone.text, _otp.text);

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      return;
    }

    setState(() => _verified = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Mobile verified')));
  }

  void _register() async {
    final success = widget.userRole == UserRole.student
        ? await ApiService.registerStudent(
            _name.text,
            _college.text.isEmpty ? null : _college.text,
            _phone.text,
          )
        : await ApiService.registerMerchant(
            _name.text,
            _company.text,
            _tax.text,
            _phone.text,
          );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userRole == UserRole.student;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userRole.name} Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStudent
                    ? 'Student Registration'
                    : 'Merchant Registration',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText:
                      isStudent ? 'Full Name' : 'Merchant Name',
                  border: const OutlineInputBorder(),
                ),
              ),

              if (isStudent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _college,
                    decoration: const InputDecoration(
                      labelText: 'College ID (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              if (!isStudent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _company,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              if (!isStudent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _tax,
                    decoration: const InputDecoration(
                      labelText: 'Tax ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: _phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              if (!_otpSent)
                ElevatedButton(
                  onPressed: _sendOtp,
                  child: const Text('SEND OTP'),
                ),

              if (_otpSent && !_verified) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otp,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text('VERIFY OTP'),
                ),
              ],

              if (_verified) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _register,
                  child: const Text('COMPLETE REGISTRATION'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
