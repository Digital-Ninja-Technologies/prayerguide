import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/pg_colors.dart';
import '../../widgets/pg_back_button.dart';

/// Scans a QR code and pops with the raw scanned text — the caller (see
/// [CompanionRepository.redeemInvite]) handles extracting the invite code
/// whether it's a bare code or a full shared link.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    context.pop(raw);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: PgBackButton(
                    icon: Icons.close_rounded, onTap: () => context.pop()),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: c.teal, width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Text(
              'Point your camera at their invite QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
