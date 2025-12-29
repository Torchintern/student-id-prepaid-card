import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MerchantMyInfoScreen extends StatefulWidget {
  final String merchantMobile;

  const MerchantMyInfoScreen({
    super.key,
    required this.merchantMobile,
  });

  @override
  State<MerchantMyInfoScreen> createState() =>
      _MerchantMyInfoScreenState();
}

class _MerchantMyInfoScreenState extends State<MerchantMyInfoScreen> {
  Map<String, dynamic>? info;

  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();

  bool _addingEmail = false;
  bool _addingAadhaar = false;
  bool _otpSent = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final data =
        await ApiService.getMerchantMyInfo(widget.merchantMobile);

    if (mounted && data != null) {
      setState(() {
        info = data;
        _emailController.text = data['email'] ?? '';
        _aadhaarController.text = data['aadhaar'] ?? '';
      });
    }
  }

  bool get _canAddEmail =>
      (info?['email'] == null || info!['email'].toString().isEmpty);

  bool get _canAddAadhaar =>
      (info?['aadhaar'] == null || info!['aadhaar'].toString().isEmpty);

  Future<void> _sendOtp() async {
    await ApiService.sendOtp(widget.merchantMobile);
    setState(() => _otpSent = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent')),
    );
  }

  Future<void> _verifyAndSave() async {
    if (_otpController.text.isEmpty) return;

    setState(() => _saving = true);

    final success = await ApiService.updateMerchantInfo(
      mobile: widget.merchantMobile,
      otp: _otpController.text,
      email: _addingEmail ? _emailController.text : null,
      aadhaar: _addingAadhaar ? _aadhaarController.text : null,
    );

    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved & Verified Successfully')),
      );
      _resetState();
      _loadInfo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verification failed')),
      );
    }
  }

  void _resetState() {
    setState(() {
      _addingEmail = false;
      _addingAadhaar = false;
      _otpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _readOnly('Merchant Name', info!['merchant_name']),
            _readOnly('Company Name', info!['company_name']),
            _readOnly('Business Type', info!['business_type']),
            _readOnly('Mobile Number', info!['mobile']),
            const Divider(height: 30),

            _fieldWithAddOption(
              label: 'Email',
              controller: _emailController,
              canAdd: _canAddEmail,
              isAdding: _addingEmail,
              onAdd: () {
                setState(() {
                  _addingEmail = true;
                  _addingAadhaar = false;
                });
              },
            ),

            const SizedBox(height: 16),

            _fieldWithAddOption(
              label: 'Aadhaar Number',
              controller: _aadhaarController,
              canAdd: _canAddAadhaar,
              isAdding: _addingAadhaar,
              keyboardType: TextInputType.number,
              maxLength: 12,
              onAdd: () {
                setState(() {
                  _addingAadhaar = true;
                  _addingEmail = false;
                });
              },
            ),

            if (_addingEmail || _addingAadhaar) ...[
              const SizedBox(height: 20),

              if (!_otpSent)
                ElevatedButton(
                  onPressed: _sendOtp,
                  child: const Text('Send OTP'),
                ),

              if (_otpSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _verifyAndSave,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Verify & Save'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _fieldWithAddOption({
    required String label,
    required TextEditingController controller,
    required bool canAdd,
    required bool isAdding,
    required VoidCallback onAdd,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: isAdding,
            keyboardType: keyboardType,
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (canAdd && !isAdding)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
      ],
    );
  }
}
