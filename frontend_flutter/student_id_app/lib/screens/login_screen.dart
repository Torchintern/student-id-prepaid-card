import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/user_role.dart';
import '../models/merchant_model.dart';
import 'dashboard_screens.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.student;
  UserRole _currentRole = UserRole.student; // ADD THIS LINE
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  bool _otpSent = false;
  int _secondsRemaining = 30;
  late Timer _timer;
  
  // Admin credentials (hardcoded)
  final Map<String, String> _adminCredentials = {
    'admin1': 'Admin@123',
    'admin2': 'Secure@456',
    'superadmin': 'Super@789',
  };

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ========== STUDENT LOGIC ==========
  void _sendOTP() {
    if (_phoneController.text.length == 10) {
      setState(() {
        _otpSent = true;
        _secondsRemaining = 30;
        _currentRole = UserRole.student;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to +91 ${_phoneController.text}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resendOTP() {
    setState(() {
      _secondsRemaining = 30;
    });
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent again'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ========== ADMIN LOGIC ==========
  void _adminLogin() {
    final username = _adminPasswordController.text.split(':')[0];
    final password = _adminPasswordController.text.split(':')[1];
    
    if (_adminCredentials[username] == password) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminDashboard(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid admin credentials'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========== MERCHANT LOGIC ==========
  void _merchantSendOTP() {
    if (_phoneController.text.length == 10) {
      // Check if phone belongs to approved merchant
      if (Merchant.isApprovedMerchant(_phoneController.text)) {
        setState(() {
          _otpSent = true;
          _secondsRemaining = 30;
          _currentRole = UserRole.merchant;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to +91 ${_phoneController.text}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This phone number is not registered as a merchant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _merchantLogin() {
    if (_otpController.text.length == 6) {
      // Get merchant details (only name and ID)
      final merchantDetails = Merchant.getMerchantDetails(_phoneController.text);
      
      if (merchantDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantDashboard(
              merchantId: merchantDetails['id']!,
              merchantName: merchantDetails['name']!,
              companyName: merchantDetails['company']!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merchant verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _studentLogin() {
    if (_otpController.text.length == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentDashboard(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF4361EE).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4361EE).withOpacity(0.3), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.school, size: 60, color: Color(0xFF4361EE)),
                ),
              ),
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Student ID Card System',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D3557),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Campus Payments',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              
              // Role Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    _buildRoleButton(UserRole.student, Icons.school, 'Student'),
                    _buildRoleButton(UserRole.merchant, Icons.store, 'Merchant'),
                    _buildRoleButton(UserRole.admin, Icons.admin_panel_settings, 'Admin'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // ========== STUDENT FORM ==========
              if (_selectedRole == UserRole.student) ...[
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                    suffixIcon: !_otpSent ? IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendOTP,
                    ) : null,
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 20),
                
                if (_otpSent && _currentRole == UserRole.student) ...[
                  TextField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 10),
                  Text('Resend OTP in $_secondsRemaining seconds'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _studentLogin,
                    child: const Text('STUDENT LOGIN'),
                  ),
                ],
              ],
              
              // ========== MERCHANT FORM ==========
              if (_selectedRole == UserRole.merchant) ...[
                const Text(
                  'Merchant Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use registered merchant phone number',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Registered Phone Number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                    suffixIcon: !_otpSent ? IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _merchantSendOTP,
                    ) : null,
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 20),
                
                if (_otpSent && _currentRole == UserRole.merchant) ...[
                  TextField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 10),
                  Text('Resend OTP in $_secondsRemaining seconds'),
                  const SizedBox(height: 20),
                  
                  // Show merchant details after OTP verification
                  FutureBuilder<Map<String, String>?>(
                    future: Future.value(Merchant.getMerchantDetails(_phoneController.text)),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Text('Verified Merchant:', 
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text('${snapshot.data!['name']}',
                                  style: const TextStyle(fontSize: 16)),
                                Text('ID: ${snapshot.data!['id']}',
                                  style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                  
                  ElevatedButton(
                    onPressed: _merchantLogin,
                    child: const Text('MERCHANT LOGIN'),
                  ),
                ],
              ],
              
              // ========== ADMIN FORM ==========
              if (_selectedRole == UserRole.admin) ...[
                const Text(
                  'Admin Access Only',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use format: username:password\nExample: admin1:Admin@123',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _adminPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Username:Password',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                
                // Show admin credentials (for reference)
                Card(
                  color: Colors.blue[50],
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Credentials:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 6),
                        Text('• admin1:Admin@123'),
                        Text('• admin2:Secure@456'),
                        Text('• superadmin:Super@789'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: _adminLogin,
                  child: const Text('ADMIN LOGIN'),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Register Button (only for students)
              if (_selectedRole == UserRole.student)
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(userRole: _selectedRole),
                      ),
                    );
                  },
                  child: const Text('REGISTER AS STUDENT'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(UserRole role, IconData icon, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _otpSent = false;
          _phoneController.clear();
          _otpController.clear();
          _adminPasswordController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedRole == role ? const Color(0xFF4361EE) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: _selectedRole == role ? Colors.white : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: _selectedRole == role ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
  }
}