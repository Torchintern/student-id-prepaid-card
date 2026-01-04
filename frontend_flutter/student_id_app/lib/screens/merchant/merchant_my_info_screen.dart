import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import 'merchant_document_preview.dart';

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
  final _dobController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _gstController = TextEditingController();
  final _otpController = TextEditingController();
  // final DateFormat _dobFormat = DateFormat('yyyy-MM-dd');

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _gstDoc;

  bool _addingEmail = false;
  bool _otpSent = false;
  bool _saving = false;

  bool _aadhaarInitialized = false;
  bool _gstInitialized = false;

  bool _aadhaarSubmitted = false;
  bool _gstSubmitted = false;

  String _initialEmail = '';
  String _initialDob = '';
  String? _initialAadhaar;
  String? _initialGst;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  // ================= LOAD =================
  Future<void> _loadInfo() async {
    final data =
        await ApiService.getMerchantMyInfo(widget.merchantMobile);

    if (!mounted || data == null) return;

    setState(() {
      info = data;

      _emailController.text = data['email'] ?? '';

      if (data['dob'] != null && data['dob'].toString().isNotEmpty) {
  _dobController.text = data['dob'].toString(); // yyyy-mm-dd
  _initialDob = _dobController.text;
} else {
  _dobController.text = '';
  _initialDob = '';
}



      if (!_aadhaarInitialized && (data['aadhaar'] ?? '').isNotEmpty) {
        _aadhaarController.text = data['aadhaar'];
        _initialAadhaar = data['aadhaar'];
        _aadhaarInitialized = true;
      }

      if (!_gstInitialized && (data['gst_number'] ?? '').isNotEmpty) {
        _gstController.text = data['gst_number'];
        _initialGst = data['gst_number'];
        _gstInitialized = true;
      }

      _initialEmail = _emailController.text;
      _initialDob = _dobController.text;

      _aadhaarSubmitted = aadhaarVerified;
      _gstSubmitted = gstVerified;

      _addingEmail = false;
      _otpSent = false;
    });
  }

  // ================= FLAGS =================
  bool get emailVerified => info?['email_verified'] == 1;
  bool get aadhaarVerified => info?['aadhaar_verified'] == 1;
  bool get gstVerified => info?['gst_verified'] == 1;
  bool get dobVerified => info?['dob'] != null;

  bool get aadhaarReady =>
      _aadhaarController.text.length == 12 &&
      _aadhaarFront != null &&
      _aadhaarBack != null;

  bool get gstReady =>
      _gstController.text.isNotEmpty && _gstDoc != null;

  bool get _hasChanges =>
      _emailController.text != _initialEmail ||
      _dobController.text != _initialDob ||
      (_aadhaarController.text != (_initialAadhaar ?? '') &&
          !aadhaarVerified &&
          !_aadhaarSubmitted) ||
      (_gstController.text != (_initialGst ?? '') &&
          !gstVerified &&
          !_gstSubmitted) ||
      (_aadhaarFront != null && !aadhaarVerified && !_aadhaarSubmitted) ||
      (_aadhaarBack != null && !aadhaarVerified && !_aadhaarSubmitted) ||
      (_gstDoc != null && !gstVerified && !_gstSubmitted);

  int get kycPercent {
    int done = 0;
    if (dobVerified) done++;
    if (emailVerified) done++;
    if (aadhaarVerified) done++;
    if (gstVerified) done++;
    return ((done / 4) * 100).round();
  }

  // ================= OTP =================
  Future<void> _sendOtp() async {
    final ok = await ApiService.sendOtp(
      mobile: widget.merchantMobile,
      role: "merchant",
    );

    if (ok && mounted) {
      setState(() => _otpSent = true);
    }
  }

  Future<void> _verifyAndSaveEmail() async {
    setState(() => _saving = true);

    final verified = await ApiService.verifyOtpNamed(
      mobile: widget.merchantMobile,
      otp: _otpController.text.trim(),
    );

    if (!verified) {
      setState(() => _saving = false);
      return;
    }

    await ApiService.updateMerchantInfo(
      mobile: widget.merchantMobile,
      email: _emailController.text.trim(),
    );

    _otpController.clear();
    await _loadInfo();
  }

  // ================= FILE PICK =================
  Future<void> _pickFile({
    required bool aadhaar,
    bool front = false,
  }) async {
    if ((aadhaar && (aadhaarVerified || _aadhaarSubmitted)) ||
        (!aadhaar && (gstVerified || _gstSubmitted))) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result?.files.single.path == null) return;

    setState(() {
      final file = File(result!.files.single.path!);
      if (aadhaar) {
        front ? _aadhaarFront = file : _aadhaarBack = file;
      } else {
        _gstDoc = file;
      }
    });
  }

  // ================= CANCEL =================
  void _handleCancel() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Unsaved Changes"),
          content: const Text(
            "You have unsaved changes. Do you want to discard them?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Stay"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetToOriginalValues();
              },
              child: const Text("Discard"),
            ),
          ],
        ),
      );
    }
  }

  void _resetToOriginalValues() {
    setState(() {
      _emailController.text = _initialEmail;
      _dobController.text = _initialDob;

      if (!aadhaarVerified && !_aadhaarSubmitted) {
        _aadhaarController.text = _initialAadhaar ?? '';
        _aadhaarFront = null;
        _aadhaarBack = null;
      }

      if (!gstVerified && !_gstSubmitted) {
        _gstController.text = _initialGst ?? '';
        _gstDoc = null;
      }

      _otpController.clear();
      _addingEmail = false;
      _otpSent = false;
      _saving = false;
    });
  }

  // ================= SAVE =================
  Future<void> _saveAndExit() async {
    if (!_hasChanges) return;

    setState(() => _saving = true);

    try {
      if (_dobController.text != _initialDob) {
        await ApiService.updateMerchantInfo(
          mobile: widget.merchantMobile,
          dob: _dobController.text.trim(),
        );
      }

      if (_emailController.text != _initialEmail && emailVerified) {
        await ApiService.updateMerchantInfo(
          mobile: widget.merchantMobile,
          email: _emailController.text.trim(),
        );
      }

      await _loadInfo();

      if (!mounted) return;

      _showStatusDialog(
        Icons.check_circle,
        Colors.green,
        "Saved",
        "Your details have been saved successfully",
      );

      await Future.delayed(const Duration(seconds: 1));
    } catch (_) {
      if (!mounted) return;

      _showStatusDialog(
        Icons.error,
        Colors.red,
        "Failed",
        "Unable to save details. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showStatusDialog(
    IconData icon,
    Color color,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("My Info & KYC"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _kycProgressBar(),
          _card(
            "My Details",
            Column(
              children: [
                _readOnly("Merchant Name", info!['merchant_name']),
                _readOnly("Company Name", info!['company_name']),
                _readOnly("Business Type", info!['business_type']),
                _readOnly("Mobile Number", info!['mobile']),
                _dobField(),
                _verifiedField(
                  label: "Email",
                  controller: _emailController,
                  verified: emailVerified,
                  enabled: !emailVerified,
                ),
                
                if (!emailVerified && !_addingEmail)
                  TextButton(
                    onPressed: () =>
                        setState(() => _addingEmail = true),
                    child: const Text("Verify Email"),
                  ),
                if (_addingEmail) _otpBlock(),
              ],
            ),
          ),
          _kycCard(
            title: "Aadhaar KYC",
            verified: aadhaarVerified,
            submitted: _aadhaarSubmitted,
            controller: _aadhaarController,
            maxLength: 12,
            uploads: [
              _uploadBox(
                "Upload Aadhaar Front",
                _aadhaarFront,
                () => _pickFile(aadhaar: true, front: true),
              ),
              _uploadBox(
                "Upload Aadhaar Back",
                _aadhaarBack,
                () => _pickFile(aadhaar: true),
              ),
            ],
            canVerify: aadhaarReady,
            onVerify: () async {
              await ApiService.uploadAadhaar(
                mobile: widget.merchantMobile,
                aadhaar: _aadhaarController.text.trim(),
                front: _aadhaarFront!,
                back: _aadhaarBack!,
              );
              setState(() => _aadhaarSubmitted = true);
            },
          ),
          _kycCard(
            title: "GST KYC",
            verified: gstVerified,
            submitted: _gstSubmitted,
            controller: _gstController,
            uploads: [
              _uploadBox(
                "Upload GST Document",
                _gstDoc,
                () => _pickFile(aadhaar: false),
              ),
            ],
            canVerify: gstReady,
            onVerify: () async {
              await ApiService.uploadGst(
                mobile: widget.merchantMobile,
                gst: _gstController.text.trim(),
                file: _gstDoc!,
              );
              setState(() => _gstSubmitted = true);
            },
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _handleCancel,
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed:
                    (_hasChanges && !_saving) ? _saveAndExit : null,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _otpBlock() => Column(
        children: [
          if (!_otpSent)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  _emailController.text.isEmpty ? null : _sendOtp,
              child: const Text("Send OTP"),
            ),
          if (_otpSent) ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Enter OTP"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _saving ? null : _verifyAndSaveEmail,
              child: const Text("Verify OTP"),
            ),
          ]
        ],
      );

  Widget _kycProgressBar() => Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(value: kycPercent / 100),
            ),
            const SizedBox(width: 12),
            Text("$kycPercent% completed"),
          ],
        ),
      );

  Widget _kycCard({
    required String title,
    required bool verified,
    required bool submitted,
    required TextEditingController controller,
    int? maxLength,
    required List<Widget> uploads,
    required bool canVerify,
    required VoidCallback onVerify,
  }) =>
      _card(
        title,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (verified)
              _status("Verified", Colors.green)
            else if (submitted)
              _status("Verification Pending", Colors.orange)
            else
              const Text(
                "Provide details",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
              ),
            TextField(
              controller: controller,
              enabled: !verified && !submitted,
              keyboardType: TextInputType.number,
              maxLength: maxLength,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: _inputDecoration("Number", counter: ""),
            ),
            if (!verified && !submitted) ...uploads,
            if (!verified)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    canVerify && !submitted ? onVerify : null,
                child: const Text("Verify"),
              ),
          ],
        ),
      );

  Widget _status(String text, Color color) => Row(
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold),
          ),
        ],
      );

  Widget _verifiedField({
  required String label,
  required TextEditingController controller,
  required bool verified,
  bool enabled = true,
  VoidCallback? onTap,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: enabled ? onTap : null,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          suffixIcon: Icon(
            verified ? Icons.check_circle : Icons.pending,
            color: verified ? Colors.green : Colors.orange,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
Widget _dobField() => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _dobController, 
        readOnly: true,
        onTap: dobVerified
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _dobController.text =
                        DateFormat('yyyy-MM-dd').format(picked);
                  });
                }
              },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          labelText: "Date of Birth",
          hintText: "Select date",
          filled: true,
          fillColor: Colors.grey.shade100,
          suffixIcon: Icon(
            dobVerified ? Icons.check_circle : Icons.calendar_today,
            color: dobVerified ? Colors.green : Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );



  Widget _uploadBox(
    String label,
    File? file,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: file != null ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.upload_file),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file != null
                      ? file.path.split('/').last
                      : label,
                ),
              ),
              if (file != null)
                TextButton(
                  child: const Text("Preview"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MerchantDocumentPreview(file: file),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );

 Widget _readOnly(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: TextEditingController(text: value),
        enabled: false,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );



  InputDecoration _inputDecoration(
  String label, {
  Widget? suffix,
  String? counter,
  bool filled = false,
}) =>
    InputDecoration(
      labelText: label,
      suffixIcon: suffix,
      counterText: counter,
      filled: filled,
      fillColor: filled ? Colors.grey.shade100 : Colors.transparent,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );


  Widget _card(String title, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}
