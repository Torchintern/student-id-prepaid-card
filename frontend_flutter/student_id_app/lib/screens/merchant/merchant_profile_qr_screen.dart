import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // ✅ REQUIRED FIX
import 'package:qr_flutter/qr_flutter.dart';

class MerchantProfileQrScreen extends StatefulWidget {
  final String merchantMobile;
  final String merchantName;
  final String companyName;

  const MerchantProfileQrScreen({
    super.key,
    required this.merchantMobile,
    required this.merchantName,
    required this.companyName,
  });

  @override
  State<MerchantProfileQrScreen> createState() =>
      _MerchantProfileQrScreenState();
}

class _MerchantProfileQrScreenState extends State<MerchantProfileQrScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _qrKey = GlobalKey();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    /// Auto-brightness friendly UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ================= SHARE / DOWNLOAD =================
  Future<void> _shareQr() async {
    final boundary = _qrKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR image ready to share or download'),
      ),
    );

    // Hook to Share/Gallery later if needed
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = {
      "type": "WALLET_PROFILE",
      "merchant_mobile": widget.merchantMobile,
      "merchant_name": widget.merchantName,
      "company_name": widget.companyName,
    };

    final qrString = jsonEncode(qrPayload);
    final initials = widget.companyName.isNotEmpty
        ? widget.companyName[0].toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Wallet QR',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQr,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              /// MERCHANT INFO
              Text(
                widget.companyName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.merchantName,
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 30),

              /// ANIMATED GLOW QR
              RepaintBoundary(
                key: _qrKey,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, __) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(
                                0.3 + _glowController.value * 0.4),
                            blurRadius:
                                30 + _glowController.value * 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: qrString,
                            size: 240,
                            backgroundColor: Colors.white,
                          ),

                          /// MERCHANT LOGO
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              /// INFO
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_scanner,
                        color: Colors.blue, size: 26),
                    SizedBox(height: 8),
                    Text(
                      'Scan this QR to pay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Fast • Secure • Contactless',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
