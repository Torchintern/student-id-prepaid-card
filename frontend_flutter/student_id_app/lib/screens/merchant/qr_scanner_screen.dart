import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _flashOn = false;
  bool _scannedOnce = false;

  final MobileScannerController _controller =
      MobileScannerController(autoStart: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermission();
  }

  // Handle app lifecycle (important!)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasPermission) return;

    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    setState(() {
      _hasPermission = status.isGranted;
      if (_hasPermission) {
        _controller.start();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // ================= GALLERY SCAN =================
  Future<void> _scanFromGallery() async {
    _controller.stop(); // stop camera before gallery

    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      _controller.start(); // restart if cancelled
      return;
    }

    _scannedOnce = false;
    await _controller.analyzeImage(image.path);

    // restart camera after analysis
    _controller.start();
  }

  // ================= HANDLE RESULT =================
  void _handleResult(String raw) {
    if (_scannedOnce) return;
    _scannedOnce = true;

    try {
      final decoded = jsonDecode(raw);
      _controller.stop();
      Navigator.pop(context, decoded);
    } catch (_) {
      _scannedOnce = false;
      _show('Invalid QR code');
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('Scan QR'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: const Center(
          child: Text(
            'Camera permission required',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Scan QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          _iconButton(
            icon: _flashOn ? Icons.flash_on : Icons.flash_off,
            onTap: () {
              _controller.toggleTorch();
              setState(() => _flashOn = !_flashOn);
            },
          ),
          _iconButton(
            icon: Icons.image,
            onTap: _scanFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          /// CAMERA VIEW
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;

              final raw = capture.barcodes.first.rawValue;
              if (raw != null) {
                _handleResult(raw);
              }
            },
          ),

          /// MASK OVERLAY (NOT WHITE SCREEN)
          _ScannerMask(),

          /// SCAN FRAME
          Center(
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue,
                  width: 3,
                ),
              ),
            ),
          ),

          /// INSTRUCTIONS
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner,
                      color: Colors.blue, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Align the QR code within the frame',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Scanning will start automatically',
                    style:
                        TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFE9F2FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue),
        ),
      ),
    );
  }
}

/// 🔳 Scanner mask widget (cuts hole for camera)
class _ScannerMask extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = 260.0;
        final left = (constraints.maxWidth - size) / 2;
        final top = (constraints.maxHeight - size) / 2;

        return Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.45)),
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
