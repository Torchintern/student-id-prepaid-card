import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/api_service.dart';
import 'qr_scanner_screen.dart';
import 'payment_result_screen.dart';

class MerchantWalletQrScreen extends StatefulWidget {
  final String merchantMobile;
  final String merchantName;
  final String companyName;

  const MerchantWalletQrScreen({
    super.key,
    required this.merchantMobile,
    required this.merchantName,
    required this.companyName,
  });

  @override
  State<MerchantWalletQrScreen> createState() =>
      _MerchantWalletQrScreenState();
}

class _MerchantWalletQrScreenState
    extends State<MerchantWalletQrScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _amountController =
      TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();


  Map<String, dynamic>? _qrPayload;
  Timer? _expiryTimer;
  Timer? _paymentPoller;

  int _secondsLeft = 120;
  bool _expired = false;

  /// Used for payment success & future wallet balance update
  bool _credited = false;

  bool _paying = false;

  bool get _qrActive => _qrPayload != null && !_expired;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
void dispose() {
  _expiryTimer?.cancel();
  _paymentPoller?.cancel();
  _amountController.dispose();
  _upiController.dispose();
  _pinController.dispose();
  _tabController.dispose();
  super.dispose();
}


  // ================= RECEIVE LOGIC =================
  void _generateWalletQr() {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _show('Enter a valid amount');
      return;
    }

    setState(() {
      _expired = false;
      _credited = false;
    });

    _qrPayload = {
      "type": "WALLET",
      "merchant_mobile": widget.merchantMobile,
      "merchant_name": widget.merchantName,
      "company_name": widget.companyName,
      "amount": amount,
      "created_at": DateTime.now().toIso8601String(),
    };

    _startExpiryTimer();
    _startPaymentPolling();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _secondsLeft = 120;

    _expiryTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        _paymentPoller?.cancel();
        setState(() => _expired = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startPaymentPolling() {
    _paymentPoller?.cancel();

    _paymentPoller =
        Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _qrPayload == null || _expired) {
        timer.cancel();
        return;
      }

      try {
        final res = await ApiService.checkWalletPayment(
          merchantMobile: widget.merchantMobile,
          createdAt: _qrPayload!['created_at'],
        );

        if (res['status'] == 'SUCCESS') {
          timer.cancel();
          _expiryTimer?.cancel();

          if (!mounted) return;

          setState(() => _credited = true);

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentResultScreen(
                success: true,
                title: 'Payment Successful',
                amount:
                    (res['amount'] ?? _qrPayload!['amount']).toDouble(),
                bankName: 'Wallet',
                reference: res['reference'] ?? 'N/A',
                actionLabel: 'Done',
              ),
            ),
          );

          _cancelQr();
        }
      } catch (_) {}
    });
  }

  void _cancelQr() {
    _expiryTimer?.cancel();
    _paymentPoller?.cancel();
    setState(() {
      _qrPayload = null;
      _expired = false;
      _credited = false;
    });
  }

  // ================= PAY FLOW =================
  Future<void> _startPayFlow() async {
  final scanResult = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const QRScannerScreen(),
    ),
  );

  if (scanResult == null || scanResult is! Map) return;

  final data = scanResult as Map<String, dynamic>;

  _openAmountSheet(
    receiverName: data['merchant_name'] ?? 'Merchant',
    receiverUpi: data['merchant_mobile'] ?? '',
  );
}

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
  // ===== PAY FLOW HELPERS =====

void _openAmountSheet({
  required String receiverName,
  required String receiverUpi,
}) {
  final amountController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _card(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Amount',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  /// CANCEL BUTTON
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
                      onPressed: () {
                        Navigator.pop(context); // back to Pay tab
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// CONFIRM (BLUE TICK)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        if (amountController.text.isEmpty) {
                          _show('Enter amount');
                          return;
                        }
                        Navigator.pop(context);
                        _openPinSheet(
                          amount:
                              double.parse(amountController.text),
                          receiverName: receiverName,
                          receiverUpi: receiverUpi,
                        );
                      },
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
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
  );
}



void _openPinSheet({
  required double amount,
  required String receiverName,
  required String receiverUpi,
}) {
  _pinController.clear();

  int pinAttempts = 0;
  String? errorMessage;
  bool locked = false;
  bool loading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _card(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter 4 Digit PIN',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _pinController,
                  maxLength: 4,
                  obscureText: true,
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: locked ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    /// CANCEL BUTTON
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
                        onPressed: () {
                          Navigator.pop(context); // back to Pay tab
                        },
                        child: const Text(
                          'Cancel',
                          style:
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// CONFIRM BUTTON
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              locked ? Colors.grey : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: locked || loading
                            ? null
                            : () async {
                                if (_pinController.text.length != 4) {
                                  setModalState(() {
                                    errorMessage =
                                        'Enter valid 4 digit PIN';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  loading = true;
                                  errorMessage = null;
                                });

                                try {
                                  final res =
                                      await ApiService.merchantPay(
                                    mobile:
                                        widget.merchantMobile,
                                    receiver: receiverUpi,
                                    amount: amount,
                                    pin: _pinController.text
                                        .trim(),
                                  );

                                  loading = false;

                                  if (res['status'] ==
                                      'SUCCESS') {
                                    Navigator.pop(context);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PaymentResultScreen(
                                          success: true,
                                          title:
                                              'Payment Successful',
                                          amount: amount,
                                          bankName:
                                              receiverName,
                                          reference:
                                              receiverUpi,
                                          actionLabel: 'Done',
                                        ),
                                      ),
                                    );
                                  } else {
                                    pinAttempts++;

                                    setModalState(() {
                                      if (pinAttempts >=
                                          3) {
                                        locked = true;
                                        errorMessage =
                                            'PIN Locked. Change PIN';
                                      } else {
                                        errorMessage =
                                            'Wrong PIN';
                                      }
                                    });
                                  }
                                } catch (_) {
                                  pinAttempts++;

                                  setModalState(() {
                                    loading = false;
                                    if (pinAttempts >= 3) {
                                      locked = true;
                                      errorMessage =
                                          'PIN Locked. Change PIN';
                                    } else {
                                      errorMessage =
                                          'Wrong PIN';
                                    }
                                  });
                                }
                              },
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirm',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold),
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
  );
}



  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('QR Payments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          tabs: const [Tab(text: 'Receive'), Tab(text: 'Pay')],
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
    final qrString =
        _qrPayload == null ? null : jsonEncode(_qrPayload);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Amount',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  enabled: !_qrActive,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: _qrActive
                        ? Colors.grey.shade200
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _qrActive ? null : _generateWalletQr,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Generate QR',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_qrActive) ...[
            const SizedBox(height: 20),

            if (_credited) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Payment received',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _card(
              Column(
                children: [
                  Text(
                    widget.companyName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.merchantName,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${_qrPayload!['amount']}',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: qrString!,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text('Expires in $_secondsLeft sec'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _cancelQr,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= PAY TAB =================
  Widget _payTab() {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter UPI ID',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
  controller: _upiController,
  keyboardType: TextInputType.text,
  decoration: InputDecoration(
    hintText: 'Mobile Number or UPI ID',
    filled: true,
    fillColor: Colors.grey.shade100,
    prefixIcon: const Icon(Icons.account_balance_wallet),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  ),
),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_upiController.text.isEmpty) {
                      _show('Enter UPI ID');
                      return;
                    }
                    _openAmountSheet(
                      receiverName: 'UPI User',
                      receiverUpi: _upiController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Pay',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        GestureDetector(
          onTap: _paying ? null : _startPayFlow,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.qr_code_scanner,
                    size: 40, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Scan & Pay',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
