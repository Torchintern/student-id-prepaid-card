import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/api_service.dart';
import 'dashboard_screens.dart';
import 'registration_screen.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _role = UserRole.student;

  final TextEditingController _mobileController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _obscureOtp = true;
  String _otpError = '';
  bool _otpSent = false;
  bool _otpVerified = false;
  int _otpTimer = 30;
  bool _canResendOtp = false;
  Timer? _timer;
  bool _otpTimerStarted = false;

  String _statusMessage = '';
  IconData? _statusIcon;
  Color _statusColor = Colors.blue;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFFEFF6FF);

  bool _isValidMobile(String mobile) =>
      RegExp(r'^\d{10}$').hasMatch(mobile);

  IconData get _roleIcon {
    switch (_role) {
      case UserRole.student:
        return Icons.school;
      case UserRole.merchant:
        return Icons.storefront;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  void _setStatus(String msg, IconData icon, Color color) {
    setState(() {
      _statusMessage = msg;
      _statusIcon = icon;
      _statusColor = color;
    });
  }

  // ================= SEND OTP =================
  Future<void> _sendOtp() async {
    if (!_isValidMobile(_mobileController.text)) {
      _setStatus('Invalid mobile number', Icons.error, Colors.red);
      return;
    }

    _setStatus('Sending OTP...', Icons.hourglass_top, Colors.orange);

    final response = await ApiService.sendOtpLogin(
      _mobileController.text,
      _role.name,
    );

    if (!response['success']) {
      setState(() {
        _otpSent = false;
      });

      _setStatus(response['message'], Icons.close, Colors.red);
      return;
    }
    setState(() {
      _otpSent = true;
    });

    _setStatus('OTP Sent', Icons.check_circle, Colors.green);
    _openOtpSheet();
  }

  // ================= VERIFY OTP =================
  Future<void> _verifyOtp() async {
  final otp = _otpControllers.map((e) => e.text).join();

  if (otp.length != 6) {
    setState(() {
      _otpError = 'Enter complete OTP';
    });
    return;
  }

  final success =
      await ApiService.login(_mobileController.text, otp);

  if (!success) {
    for (final c in _otpControllers) {
      c.clear();
    }

    setState(() {
      _otpError = 'Invalid OTP';
    });

    _otpFocusNodes.first.requestFocus();
    return;
  }

  setState(() {
    _otpVerified = true;
    _otpError = '';
    _statusMessage = 'OTP Verified';
    _statusIcon = Icons.check_circle;
    _statusColor = Colors.green;
  });

  Navigator.pop(context);
}


  // ================= LOGIN =================
  Future<void> _login() async {
    if (!_otpVerified) return;

    if (_role == UserRole.merchant) {
      final profile =
          await ApiService.getMerchantProfile(_mobileController.text);

      if (profile == null) {
        _setStatus(
            'Unable to fetch merchant profile', Icons.close, Colors.red);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MerchantDashboard(
            merchantName: profile['merchant_name'],
            companyName: profile['company_name'],
            mobile: _mobileController.text,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _role == UserRole.student
            ? const StudentDashboard()
            : const AdminDashboard(),
      ),
    );
  }

// ================= OTP BOTTOM SHEET =================
void _startOtpTimer(StateSetter setModalState) {
  _timer?.cancel();
  _otpTimer = 30;
  _canResendOtp = false;

  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_otpTimer == 0) {
      timer.cancel();
      setModalState(() {
        _canResendOtp = true;
      });
    } else {
      setModalState(() {
        _otpTimer--;
      });
    }
  });
}

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

                // TIMER TEXT
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _canResendOtp
                        ? 'Didn’t receive OTP?'
                        : 'Resend in $_otpTimer s',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                // OTP SENT MESSAGE
                if (!_canResendOtp && _otpTimer == 30)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'OTP Sent',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // SHOW / HIDE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Enter OTP',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(
                        _obscureOtp
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setModalState(() {
                          _obscureOtp = !_obscureOtp;
                        });
                      },
                    ),
                  ],
                ),

                // OTP BOXES
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
                        obscureText: _obscureOtp,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            _otpError = '';
                          });

                          if (value.isNotEmpty && i < 5) {
                            _otpFocusNodes[i + 1].requestFocus();
                          } else if (value.isEmpty && i > 0) {
                            _otpFocusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                // INVALID OTP MESSAGE
                if (_otpError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _otpError,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // VERIFY BUTTON
                ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Verify OTP'),
                ),

                //  RESEND OTP (FIXED)
                TextButton(
  onPressed: _canResendOtp
      ? () async {
          await ApiService.sendOtpLogin(
            _mobileController.text,
            _role.name,
          );

          setModalState(() {
            _otpTimer = 30;
            _canResendOtp = false;
            _otpError = '';
          });

          _startOtpTimer(setModalState);
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

              ],
            ),
          );
        },
      );
    },
  ).then((_) {
  _otpTimerStarted = false;
});


  Future.delayed(const Duration(milliseconds: 300), () {
    _otpFocusNodes.first.requestFocus();
  });
}


  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white,
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
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              _primaryBlue.withOpacity(0.12),
                          child: Icon(
                            _roleIcon,
                            size: 30,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ToggleButtons(
                        borderRadius: BorderRadius.circular(14),
                        selectedColor: Colors.white,
                        fillColor: _primaryBlue,
                        isSelected: [
                          _role == UserRole.student,
                          _role == UserRole.merchant,
                          _role == UserRole.admin,
                        ],
                        onPressed: (index) {
                          setState(() {
                            _role = UserRole.values[index];
                            _otpSent = false;
                            _otpVerified = false;
                            _statusMessage = '';
                            _mobileController.clear();
                          });
                        },
                        children: const [
                          Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Student')),
                          Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Merchant')),
                          Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Admin')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onChanged: (_) {
                        setState(() {
                          _otpSent = false;
                          _otpVerified = false;
                          _statusMessage = '';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        suffixIcon: _otpVerified
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_statusIcon,
                                color: _statusColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _statusMessage,
                              style:
                                  TextStyle(color: _statusColor),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _otpVerified
                          ? _login
                          : (_otpSent ? null : _sendOtp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        minimumSize:
                            const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          Text(_otpVerified ? 'LOGIN' : 'SEND OTP'),
                    ),
                    const SizedBox(height: 16),
                    if (_role != UserRole.admin)
                      Column(
                        children: [
                          Text(
                            _role == UserRole.student
                                ? 'Not Yet registered to LUME?'
                                : 'Want to be LUME Merchant?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RegistrationScreen(
                                          userRole: _role),
                                ),
                              );
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
