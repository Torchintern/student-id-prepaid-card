import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

import 'merchant/all_payments_screen.dart';
import 'merchant/qr_code_screen.dart';
import 'merchant/loans_screen.dart';
import 'merchant/business_insights_screen.dart';
import 'merchant/soundpod_screen.dart';
import 'merchant/support_screen.dart';

import 'admin/student_management_screen.dart';
import 'admin/merchant_management_screen.dart';
import 'admin/reward_rules_screen.dart';
import 'admin/reports_analytics_screen.dart';

/// ================= STUDENT DASHBOARD =================
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          backgroundColor: const Color(0xFF4361EE),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Welcome Student!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= MERCHANT DASHBOARD =================
class MerchantDashboard extends StatefulWidget {
  final String merchantName;
  final String companyName;
  final String mobile;

  const MerchantDashboard({
    super.key,
    required this.merchantName,
    required this.companyName,
    required this.mobile,
  });

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _currentIndex = 0;

  void _logout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// ================= CHANGE PIN (OTP BASED) =================
  void _showChangePinFlow(BuildContext context) {
    final mobileController =
        TextEditingController(text: widget.mobile);
    final otpController = TextEditingController();
    final pinController = TextEditingController();

    bool otpSent = false;
    bool otpVerified = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change PIN',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: mobileController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Registered Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                if (!otpSent)
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await ApiService.sendOtpRegister(
                          widget.mobile);
                      if (ok) {
                        setSheetState(() => otpSent = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP sent')),
                        );
                      }
                    },
                    child: const Text('SEND OTP'),
                  ),

                if (otpSent && !otpVerified) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await ApiService.verifyOtp(
                        widget.mobile,
                        otpController.text.trim(),
                      );
                      if (ok) {
                        setSheetState(() => otpVerified = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OTP verified')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid OTP')),
                        );
                      }
                    },
                    child: const Text('VERIFY OTP'),
                  ),
                ],

                if (otpVerified) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    maxLength: 4,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New 4-digit PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final res =
                          await ApiService.changeMerchantPin(
                        mobile: widget.mobile,
                        otp: otpController.text.trim(),
                        newPin: pinController.text.trim(),
                      );

                      if (res['success']) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('PIN updated successfully')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'])),
                        );
                      }
                    },
                    child: const Text('SAVE PIN'),
                  ),
                ],
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            _currentIndex == 0 ? 'Merchant Home' : 'Merchant Profile',
            style: const TextStyle(color: Colors.black),
          ),
        ),
        body: _currentIndex == 0 ? _homeTab() : _profileTab(context),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HOME TAB =================
  Widget _homeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _merchantHeader(),
          const SizedBox(height: 16),
          _todaySalesCard(),
          const SizedBox(height: 20),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _quickActions(),
        ],
      ),
    );
  }

  /// ================= PROFILE TAB =================
  Widget _profileTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green,
            child: Icon(Icons.store, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            widget.merchantName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(widget.companyName),
          const SizedBox(height: 24),

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change PIN'),
              subtitle: const Text('OTP verification required'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showChangePinFlow(context),
            ),
          ),

          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const ListTile(
              leading: Icon(Icons.account_balance),
              title: Text('Bank Account'),
              subtitle: Text('Add / Update Bank Account'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _merchantHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.store, color: Colors.white),
        ),
        title: Text(
          'Welcome ${widget.merchantName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(widget.companyName),
      ),
    );
  }

  Widget _todaySalesCard() {
  return FutureBuilder<Map<String, dynamic>>(
    future: ApiService.getMerchantDailySummary(widget.mobile),
    builder: (context, snapshot) {
      final total = snapshot.data?['total'] ?? 0;
      final count = snapshot.data?['count'] ?? 0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.greenAccent],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Collection",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              "₹$total",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$count Transactions",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    },
  );
}


  Widget _quickActions() {
    final actions = [
      _action(Icons.receipt_long, "All Payments"),
      _action(Icons.qr_code, "QR Code"),
      _action(Icons.account_balance, "Loans"),
      _action(Icons.insights, "Business Insights"),
      _action(Icons.speaker, "SoundPod"),
      _action(Icons.support_agent, "Support"),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) => actions[i],
    );
  }

  Widget _action(IconData icon, String label) {
    return InkWell(
      onTap: () {
        Widget screen;

        switch (label) {
          case 'All Payments':
            screen = AllPaymentsScreen(
              merchantMobile: widget.mobile,
            );
            break;
          case 'QR Code':
            screen = QRCodeScreen(
              merchantMobile: widget.mobile,
              merchantName: widget.merchantName,
            );
            break;
          case 'Loans':
            screen = const LoansScreen();
            break;
          case 'Business Insights':
            screen = BusinessInsightsScreen(
  merchantMobile: widget.mobile,
);

            break;
          case 'SoundPod':
            screen = const SoundPodScreen();
            break;
          default:
            screen = const SupportScreen();
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// ================= ADMIN DASHBOARD =================
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _adminStats(),
              const SizedBox(height: 20),
              _adminActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminStats() {
    return Row(
      children: const [
        _StatCard("Active Cards", "1,245", Icons.credit_card),
        _StatCard("Transactions", "18,390", Icons.swap_horiz),
        _StatCard("Rewards Issued", "₹45K", Icons.card_giftcard),
      ],
    );
  }

  Widget _adminActions() {
    final actions = [
      _AdminAction(Icons.school, "Student Management"),
      _AdminAction(Icons.store, "Merchant Management"),
      _AdminAction(Icons.settings, "Reward Rules"),
      _AdminAction(Icons.analytics, "Reports & Analytics"),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, i) => actions[i],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(height: 6),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AdminAction(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Widget screen;

          switch (label) {
            case 'Student Management':
              screen = const StudentManagementScreen();
              break;
            case 'Merchant Management':
              screen = const MerchantManagementScreen();
              break;
            case 'Reward Rules':
              screen = const RewardRulesScreen();
              break;
            default:
              screen = const ReportsAnalyticsScreen();
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.deepPurple),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
