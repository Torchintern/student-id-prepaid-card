import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'linked_bank_account_screen.dart';

class AddBankAccountScreen extends StatefulWidget {
  final String merchantMobile;
  final String merchantName;
  final String companyName;

  const AddBankAccountScreen({
    super.key,
    required this.merchantMobile,
    required this.merchantName,
    required this.companyName,
  });

  @override
  State<AddBankAccountScreen> createState() =>
      _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  bool _checkingLink = false;
  String? _statusMessage;

  Map<String, dynamic>? _linkedAccount;
  String? _selectedBank;

  final List<String> _suggestedBanks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Punjab National Bank',
    'Kotak Mahindra Bank',
    'IDFC First Bank',
    'Indian Bank',
    'YES Bank',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= CHECK BANK LINK =================
  Future<void> _checkBank(String bankName) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _checkingLink = true;
      _statusMessage = null;
      _linkedAccount = null;
      _selectedBank = null;
    });

    final result = await ApiService.checkBankLinked(
      mobile: widget.merchantMobile,
      bankName: bankName,
    );

    if (!mounted) return;

    setState(() => _checkingLink = false);

    // ---------------- NOT LINKED ----------------
    if (result['linked'] != true) {
      setState(() {
        _statusMessage =
            'Mobile number is not linked with $bankName';
      });
      return;
    }

    // ---------------- LINKED ----------------
    _selectedBank = bankName;
    _linkedAccount = result['account'];

    _openLinkedBankAccountScreen();
  }

  // ================= OPEN LINKED BANK SCREEN =================
  void _openLinkedBankAccountScreen() {
    if (_linkedAccount == null || _selectedBank == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LinkedBankAccountScreen(
          bankName: _selectedBank!,
          accountHolderName:
              _linkedAccount!['account_holder_name']
                  ?.toString() ??
                  '-',
          accountNumber:
              _linkedAccount!['account_number']
                  ?.toString() ??
                  '-',
          ifscCode:
              _linkedAccount!['ifsc_code']
                  ?.toString() ??
                  '-',
          merchantMobile: widget.merchantMobile,
          merchantName: widget.merchantName,
          companyName: widget.companyName,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bank Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= SEARCH =================
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search your bank',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _checkBank(value.trim());
                }
              },
            ),

            const SizedBox(height: 12),

            if (_checkingLink)
              const Center(child: CircularProgressIndicator()),

            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ================= SUGGESTED BANKS =================
            const Text(
              'Popular banks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: _suggestedBanks.length,
                itemBuilder: (_, index) {
                  final bank = _suggestedBanks[index];
                  return Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.account_balance),
                      title: Text(bank),
                      onTap: () => _checkBank(bank),
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
}
