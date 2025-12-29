import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class MerchantProfileQrScreen extends StatefulWidget {
  final String merchantName;
  final String companyName;
  final String mobile;

  const MerchantProfileQrScreen({
    super.key,
    required this.merchantName,
    required this.companyName,
    required this.mobile,
  });

  @override
  State<MerchantProfileQrScreen> createState() =>
      _MerchantProfileQrScreenState();
}

class _MerchantProfileQrScreenState
    extends State<MerchantProfileQrScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQr() async {
    final file = await _captureQrImage();
    if (file != null) {
      Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Scan to pay ${widget.companyName}\nUPI: ${_upiId()}',
      );
    }
  }

  Future<void> _downloadQr() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    final file = await _captureQrImage();
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR saved to ${file.path}'),
        ),
      );
    }
  }

  Future<File?> _captureQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/merchant_qr_${widget.mobile}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  void _copyUpi() {
    Clipboard.setData(ClipboardData(text: _upiId()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UPI ID copied')),
    );
  }

  String _upiId() => '${widget.mobile}@studentpay';

  @override
  Widget build(BuildContext context) {
    final qrPayload = jsonEncode({
      'type': 'MERCHANT_PROFILE',
      'merchant_name': widget.merchantName,
      'company_name': widget.companyName,
      'mobile': widget.mobile,
      'upi_id': _upiId(),
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQr,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadQr,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.companyName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.merchantName,
              style:
                  const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            RepaintBoundary(
              key: _qrKey,
              child: QrImageView(
                data: qrPayload,
                size: 260,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Mobile Number'),
              subtitle: Text(widget.mobile),
            ),

            ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet),
              title: const Text('UPI ID'),
              subtitle: Text(_upiId()),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyUpi,
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Ask customer to scan this QR to pay',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
