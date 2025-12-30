import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_bank_account_screen.dart';
import '../merchant/merchant_profile_qr_screen.dart';

class LinkedBankAccountScreen extends StatefulWidget {
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String merchantMobile;
  final String merchantName;
  final String companyName;

  const LinkedBankAccountScreen({
    super.key,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.merchantMobile,
    required this.merchantName,
    required this.companyName,
  });

  @override
  State<LinkedBankAccountScreen> createState() =>
      _LinkedBankAccountScreenState();
}

class _LinkedBankAccountScreenState
    extends State<LinkedBankAccountScreen> {
  bool _checkingBalance = false;

  // ================= PIN DIALOG =================
  void _showPinDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Enter 4-digit PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: '••••',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length != 4) {
                _showError('Enter valid 4-digit PIN');
                return;
              }
              Navigator.pop(context);
              _verifyPinAndFetchBalance(pin);
            },
            child: const Text('Check Balance'),
          ),
        ],
      ),
    );
  }

  // ================= VERIFY PIN + FETCH BALANCE =================
  Future<void> _verifyPinAndFetchBalance(String pin) async {
    setState(() => _checkingBalance = true);

    try {
      final result = await ApiService.checkMerchantBalance(
        mobile: widget.merchantMobile,
        pin: pin,
        bankName: widget.bankName,
      );

      if (!mounted) return;

      setState(() => _checkingBalance = false);

      if (result.containsKey('balance')) {
        _showBalanceDialog(result['balance']);
      } else {
        _showError(result['message'] ?? 'Unable to fetch balance');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingBalance = false);
      _showError('Something went wrong');
    }
  }

  // ================= BALANCE DIALOG =================
  void _showBalanceDialog(dynamic balance) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Available Balance'),
        content: Text(
          '₹ ${balance.toString()}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Bank Account'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= BANK DETAILS =================
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Account Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _infoRow(
          'Bank Name',
          (widget.bankName.isNotEmpty)
              ? widget.bankName
              : 'Select bank from below',
        ),

        _infoRow(
          'Account Number',
          (widget.accountNumber.isNotEmpty)
              ? _maskAccount(widget.accountNumber)
              : '--',
        ),

        _infoRow(
          'IFSC Code',
          (widget.ifscCode.isNotEmpty)
              ? widget.ifscCode
              : '--',
        ),
      ],
    ),
  ),
),

const SizedBox(height: 24),


            // ================= MY QR CODE =================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.qr_code, size: 30),
                title: const Text(
                  'My QR Code',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Receive payments via QR'),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MerchantProfileQrScreen(
                        merchantName: widget.merchantName,
                        companyName: widget.companyName,
                        mobile: widget.merchantMobile,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= CHECK BALANCE =================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  size: 30,
                ),
                title: const Text(
                  'Check Balance',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    const Text('Verify PIN to view balance'),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _checkingBalance ? null : _showPinDialog,
              ),
            ),

            if (_checkingBalance)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),

            const Spacer(),

            // ================= ADD NEW BANK =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add New Bank Account',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddBankAccountScreen(
                        merchantMobile: widget.merchantMobile,
                        merchantName: widget.merchantName,
                        companyName: widget.companyName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskAccount(String acc) {
    if (acc.length <= 4) return acc;
    return 'XXXX XXXX ${acc.substring(acc.length - 4)}';
  }
}
