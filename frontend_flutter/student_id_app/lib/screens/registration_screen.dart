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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();

  String? _businessType;

  bool _otpSent = false;
  bool _verified = false;
  String? _otpMobile;

  final List<String> businessTypes = [
    'Sole Proprietor',
    'Partnership',
    'Private Limited',
    'Public Limited',
    'LLP',
    'Other',
  ];

  bool _isValidMobile(String m) =>
      RegExp(r'^\d{10}$').hasMatch(m);

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(e);

  // ================= SEND OTP =================
  void _sendOtp() async {
    if (!_isValidMobile(_mobile.text)) {
      _show('Enter valid 10-digit mobile number');
      return;
    }

    await ApiService.sendOtpRegister(_mobile.text);
    setState(() {
      _otpSent = true;
      _verified = false;
      _otpMobile = _mobile.text;
    });

    _show('OTP sent');
  }

  // ================= VERIFY OTP =================
  void _verifyOtp() async {
    if (_mobile.text != _otpMobile) {
      _show('Mobile number changed. Re-send OTP');
      setState(() {
        _otpSent = false;
        _verified = false;
      });
      return;
    }

    final success = await ApiService.verifyOtp(
      _mobile.text,
      _otp.text,
    );

    if (success) {
      setState(() => _verified = true);
      _show('Mobile verified');
    } else {
      _show('Invalid OTP');
    }
  }

  // ================= REGISTER =================
  void _register() async {
    if (!_verified) {
      _show('Verify mobile number first');
      return;
    }

    if (_name.text.trim().isEmpty) {
      _show('Name is required');
      return;
    }

    if (widget.userRole == UserRole.student) {
      if (!_isValidEmail(_email.text)) {
        _show('Enter valid email');
        return;
      }
    } else {
      if (_company.text.isEmpty || _businessType == null) {
        _show('All merchant details are required');
        return;
      }
    }

    final res = widget.userRole == UserRole.student
        ? await ApiService.registerStudent(
            _name.text,
            _email.text,
            _mobile.text,
          )
        : await ApiService.registerMerchant(
            _name.text,
            _company.text,
            _businessType!,
            _mobile.text,
          );

    if (!res['success']) {
      _show(res['message']);
      return;
    }

    _show('Registration successful');
    Navigator.pop(context);
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),

              if (isStudent)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
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
                  child: DropdownButtonFormField<String>(
                    value: _businessType,
                    items: businessTypes
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _businessType = v),
                    decoration: const InputDecoration(
                      labelText: 'Business Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_otpSent) {
                    setState(() {
                      _otpSent = false;
                      _verified = false;
                    });
                  }
                },
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
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
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
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
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
