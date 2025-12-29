import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import 'qr_scanner_screen.dart'; // ✅ NEW IMPORT

class QRCodeScreen extends StatefulWidget {
  final String merchantMobile;
  final String merchantName;

  const QRCodeScreen({
    super.key,
    required this.merchantMobile,
    required this.merchantName,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _receiveAmountController =
      TextEditingController();
  final TextEditingController _payTargetController =
      TextEditingController();
  final TextEditingController _payAmountController =
      TextEditingController();
  final TextEditingController _pinController =
      TextEditingController();

  int? _qrId;
  double? _qrAmount;

  String _qrStatus = 'NONE'; // NONE | PENDING | SUCCESS | EXPIRED | CANCELLED
  Timer? _expiryTimer;
  int _remainingSeconds = 120;

  bool _canEnterAmount = false;
  bool _canPay = false;

  String? _payResult; // SUCCESS | FAILED | CANCELLED

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _receiveAmountController.dispose();
    _payTargetController.dispose();
    _payAmountController.dispose();
    _pinController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ================= RECEIVE =================
  Future<void> _generateQr() async {
    final amount =
        double.tryParse(_receiveAmountController.text.trim());

    if (amount == null || amount <= 0) {
      _show('Enter valid amount');
      return;
    }

    final qrId =
        await ApiService.createQr(widget.merchantMobile, amount);

    if (qrId == null) {
      _show('Failed to generate QR');
      return;
    }

    setState(() {
      _qrId = qrId;
      _qrAmount = amount;
      _qrStatus = 'PENDING';
      _remainingSeconds = 120;
    });

    _expiryTimer?.cancel();
    _expiryTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() => _qrStatus = 'EXPIRED');
        _resetReceive();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _cancelQr() async {
    if (_qrId == null) return;
    await ApiService.cancelQr(_qrId!);

    setState(() => _qrStatus = 'CANCELLED');

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _resetReceive();
    });
  }

  void _resetReceive() {
    _expiryTimer?.cancel();
    setState(() {
      _qrId = null;
      _qrAmount = null;
      _qrStatus = 'NONE';
      _remainingSeconds = 120;
      _receiveAmountController.clear();
    });
  }

  // ================= PAY =================
  Future<void> _pay() async {
    if (!_canPay) return;

    if (_pinController.text.length != 4) {
      _show('Enter valid 4-digit PIN');
      return;
    }

    final res = await ApiService.merchantPay(
      mobile: widget.merchantMobile,
      receiver: _payTargetController.text.trim(),
      amount: double.parse(_payAmountController.text.trim()),
      pin: _pinController.text.trim(),
    );

    setState(() {
      _payResult = res['success'] ? 'SUCCESS' : 'FAILED';
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _resetPay();
    });
  }

  void _cancelPay() {
    setState(() {
      _payResult = 'CANCELLED';
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _resetPay();
    });
  }

  void _resetPay() {
    setState(() {
      _payTargetController.clear();
      _payAmountController.clear();
      _pinController.clear();
      _canEnterAmount = false;
      _canPay = false;
      _payResult = null;
    });
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _statusColor(String status) {
    return status == 'SUCCESS' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Payments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Receive'),
            Tab(text: 'Pay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_receiveTab(), _payTab()],
      ),
    );
  }

  // ================= RECEIVE TAB =================
  Widget _receiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _receiveAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount to Receive',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateQr,
            child: const Text('Generate QR'),
          ),
          const SizedBox(height: 24),

          if (_qrId != null)
            Column(
              children: [
                Text(
                  '₹${_qrAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                QrImageView(
                  data: jsonEncode({
                    'qr_id': _qrId,
                    'amount': _qrAmount,
                  }),
                  size: 220,
                ),

                const SizedBox(height: 12),
                Text(
                  widget.merchantName,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
                

                const SizedBox(height: 8),
                Text(
                  _qrStatus == 'PENDING'
                      ? 'Expires in ${_remainingSeconds}s'
                      : _qrStatus,
                  style: TextStyle(
                    color: _statusColor(_qrStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _cancelQr,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  child: const Text('Cancel'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ================= PAY TAB =================
  Widget _payTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(),
                ),
              );

              if (result != null) {
                setState(() {
                  _payTargetController.text =
                      result['qr_id'].toString();
                  _payAmountController.text =
                      result['amount'].toString();
                  _canEnterAmount = true;
                  _canPay = true;
                });
              }
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _payTargetController,
            decoration: const InputDecoration(
              labelText: 'Mobile Number or UPI ID',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                setState(() => _canEnterAmount = v.isNotEmpty),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _payAmountController,
            enabled: _canEnterAmount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                setState(() => _canPay = v.isNotEmpty),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _pinController,
            enabled: _canPay,
            maxLength: 4,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '4-digit PIN',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _canPay ? _pay : null,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _canPay ? Colors.green : Colors.grey,
              ),
              child: const Center(
                child: Text(
                  'PAY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          TextButton(
            onPressed: _cancelPay,
            child: const Text('Cancel'),
          ),

          if (_payResult != null) ...[
            const SizedBox(height: 20),
            Icon(
              _payResult == 'SUCCESS'
                  ? Icons.check_circle
                  : Icons.cancel,
              color: _statusColor(_payResult!),
              size: 80,
            ),
            const SizedBox(height: 8),
            Text(
              _payResult!,
              style: TextStyle(
                  color: _statusColor(_payResult!),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
