import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _college = TextEditingController();
  final _company = TextEditingController();
  final _gstin = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  bool _otpSent = false;
  bool _verified = false;
  String? _otpMobile;

  bool _isValidMobile(String mobile) =>
      RegExp(r'^\d{10}$').hasMatch(mobile);

  bool _isValidGSTIN(String gstin) {
    return RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9]Z[A-Z0-9]$',
    ).hasMatch(gstin);
  }

  // ================= SEND OTP =================
  void _sendOtp() async {
    if (!_isValidMobile(_phone.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit mobile number')),
      );
      return;
    }

    await ApiService.sendOtpRegister(_phone.text);
    setState(() {
      _otpSent = true;
      _verified = false;
      _otpMobile = _phone.text;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('OTP sent')));
  }

  // ================= VERIFY OTP =================
  void _verifyOtp() async {
    if (_phone.text != _otpMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number changed. Re-send OTP')),
      );
      setState(() {
        _otpSent = false;
        _verified = false;
      });
      return;
    }

    final success =
        await ApiService.verifyOtp(_phone.text, _otp.text);

    if (success) {
      setState(() => _verified = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mobile verified')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  // ================= REGISTER =================
  void _register() async {
    if (!_verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify mobile number first')),
      );
      return;
    }

    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    if (widget.userRole == UserRole.merchant) {
      if (_company.text.trim().isEmpty || _gstin.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All merchant details are required')),
        );
        return;
      }

      if (!_isValidGSTIN(_gstin.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid GSTIN format. Example: 22AAAAA0000A1Z5'),
          ),
        );
        return;
      }
    }

    final res = widget.userRole == UserRole.student
        ? await ApiService.registerStudent(
            _name.text,
            _college.text.isEmpty ? null : _college.text,
            _phone.text,
          )
        : await ApiService.registerMerchant(
            _name.text,
            _company.text,
            _gstin.text,
            _phone.text,
          );

    if (!res['success']) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res['message'])));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userRole == UserRole.student;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.userRole.name} Registration')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: isStudent ? 'Full Name' : 'Merchant Name',
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
                    controller: _gstin,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9]'),
                      ),
                      UpperCaseTextFormatter(),
                    ],
                    maxLength: 15,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: _phone,
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
                  maxLength: 6,
                  keyboardType: TextInputType.number,
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
