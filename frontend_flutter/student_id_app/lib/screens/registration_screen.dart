import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import 'dart:async';

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

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  String? _businessType;
  String? _otpMobile;

  bool _verified = false;
  bool _hideOtp = true;

  // status (login-style)
  String _statusMessage = '';
  Color _statusColor = Colors.blue;
  IconData? _statusIcon;

  // otp-tab messages
  String _otpError = '';

  int _otpTimer = 30;
  bool _canResendOtp = false;
  bool _otpTimerStarted = false;
  Timer? _timer;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFFEFF6FF);

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

  void _setStatus(String msg, Color color, {IconData? icon}) {
    setState(() {
      _statusMessage = msg;
      _statusColor = color;
      _statusIcon = icon;
    });
  }

  // ================= SEND OTP =================
  void _sendOtp() async {
    if (!_isValidMobile(_mobile.text)) {
      _setStatus('Enter valid 10-digit mobile number', Colors.red);
      return;
    }

    await ApiService.sendOtpRegister(_mobile.text);

    setState(() {
      _verified = false;
      _otpMobile = _mobile.text;
      _statusMessage = '';
      _statusIcon = null;
    });

    _openOtpSheet();
  }

  // ================= VERIFY OTP =================
  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((e) => e.text).join();

    if (otp.length != 6) {
      setState(() => _otpError = 'Enter complete OTP');
      return;
    }

    if (_mobile.text != _otpMobile) {
      setState(() => _otpError = 'Mobile number changed. Re-send OTP');
      return;
    }

    final success =
        await ApiService.verifyOtp(_mobile.text, otp);

    if (success) {
      setState(() {
        _verified = true;
        _otpError = '';
      });
      Navigator.pop(context);
      _setStatus(
        'Mobile verified',
        Colors.green,
        icon: Icons.check_circle,
      );
    } else {
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes.first.requestFocus();
      setState(() => _otpError = 'Invalid OTP');
    }
  }

  // ================= OTP TIMER =================
  void _startOtpTimer(StateSetter setModalState) {
    _timer?.cancel();
    _otpTimer = 30;
    _canResendOtp = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimer == 0) {
        timer.cancel();
        setModalState(() => _canResendOtp = true);
      } else {
        setModalState(() => _otpTimer--);
      }
    });
  }

  // ================= OTP BOTTOM SHEET =================
  void _openOtpSheet() {
    _otpError = '';
    for (final c in _otpControllers) {
      c.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!_otpTimerStarted) {
              _otpTimerStarted = true;
              _startOtpTimer(setModalState);
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Verify OTP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _canResendOtp
                          ? 'Didn’t receive OTP?'
                          : 'Resend in $_otpTimer s',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),

                  if (_otpError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _otpError,
                        style: TextStyle(
                          color: _otpError == 'OTP Sent'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enter OTP',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: Icon(
                          _hideOtp
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            _hideOtp = !_hideOtp;
                          });
                        },
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _otpControllers[i],
                          focusNode: _otpFocusNodes[i],
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          obscureText: _hideOtp,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setModalState(() => _otpError = '');
                            if (v.isNotEmpty && i < 5) {
                              _otpFocusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _otpFocusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Verify OTP'),
                  ),

                  TextButton(
  onPressed: _canResendOtp
      ? () async {
          await ApiService.sendOtpRegister(_mobile.text);
          setModalState(() {
            _otpError = 'OTP Sent';
            _otpTimerStarted = false;
          });
        }
      : null,
  child: Text(
    'Resend OTP',
    style: TextStyle(
      color: _canResendOtp
          ? _primaryBlue  
          : Colors.grey,   
      fontWeight: FontWeight.w600,
    ),
  ),
),


                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => _otpTimerStarted = false);
  }

  // ================= REGISTER =================
  void _register() async {
    if (!_verified) {
      _setStatus('Verify mobile number first', Colors.red);
      return;
    }

    if (_name.text.trim().isEmpty) {
      _setStatus('Name is required', Colors.red);
      return;
    }

    if (widget.userRole == UserRole.student) {
      if (!_isValidEmail(_email.text)) {
        _setStatus('Enter valid email', Colors.red);
        return;
      }
    } else {
      if (_company.text.isEmpty || _businessType == null) {
        _setStatus('All merchant details are required', Colors.red);
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
      _setStatus(res['message'], Colors.red);
      return;
    }

    _setStatus(
      'Registration Successful',
      Colors.green,
      icon: Icons.check_circle,
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  InputDecoration _input(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      suffixIcon: suffix,
    );
  }

  IconData get _roleIcon {
    switch (widget.userRole) {
      case UserRole.student:
        return Icons.school;
      case UserRole.merchant:
        return Icons.storefront;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userRole == UserRole.student;

    return Scaffold(
      backgroundColor: _lightBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'LUME',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: _primaryBlue.withOpacity(0.12),
                          child: Icon(_roleIcon, size: 30, color: _primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextField(controller: _name, decoration: _input('Full Name')),

                    if (isStudent) ...[
                      const SizedBox(height: 14),
                      TextField(controller: _email, decoration: _input('Email Address')),
                    ],

                    if (!isStudent) ...[
                      const SizedBox(height: 14),
                      TextField(controller: _company, decoration: _input('Company Name')),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _businessType,
                        items: businessTypes
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _businessType = v),
                        decoration: _input('Business Type'),
                      ),
                    ],

                    const SizedBox(height: 14),

                    TextField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: _input(
                        'Mobile Number',
                        suffix: _verified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    ),

                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_statusIcon != null)
                              Icon(_statusIcon, color: _statusColor, size: 20),
                            if (_statusIcon != null) const SizedBox(width: 6),
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 22),

                    ElevatedButton(
                      onPressed: _verified ? _register : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_verified ? 'REGISTER' : 'SEND OTP'),
                    ),

                    if (!_verified)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
