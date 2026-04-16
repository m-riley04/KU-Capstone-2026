import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../config/theme_config.dart';
import '../services/device_identity_store.dart';
import 'base_app.dart';

class SetupApp extends BaseApp {
  const SetupApp({super.key});

  @override
  String get appName => 'Setup';

  @override
  bool get showBackButtonWithCustomBottom => false;

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    return const SetupBottomScreenContent();
  }

  @override
  State<SetupApp> createState() => _SetupAppState();
}

class _SetupAppState extends State<SetupApp> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: EarthyTheme.background,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            decoration: BoxDecoration(
              color: EarthyTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EarthyTheme.sandstone, width: 2),
            ),
            child: Text(
              'welcome to polypod. the desktop friend that keeps you informed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EarthyTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupBottomScreenContent extends StatefulWidget {
  const SetupBottomScreenContent({super.key});

  @override
  State<SetupBottomScreenContent> createState() =>
      _SetupBottomScreenContentState();
}

class _SetupBottomScreenContentState extends State<SetupBottomScreenContent> {
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await loadOrCreateDeviceId();
    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceId = _deviceId;

    if (deviceId == null) {
      return Center(child: CircularProgressIndicator(color: EarthyTheme.wheat));
    }

    final accountUrl = Uri.https('polypod.net', '/create-account', {
      'userid': deviceId,
    }).toString();

    return Container(
      color: EarthyTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'scan to create or link account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EarthyTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              child: _QrCodeBox(data: accountUrl, size: 180),
            ),
            const SizedBox(height: 6),
            Text(
              'device id: $deviceId',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EarthyTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCodeBox extends StatelessWidget {
  const _QrCodeBox({required this.data, required this.size});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: CustomPaint(size: Size.square(size), painter: _QrPainter(qrImage)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this._qrImage);

  final QrImage _qrImage;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final moduleCount = _qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (_qrImage.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * moduleSize,
              row * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate._qrImage != _qrImage;
  }
}
