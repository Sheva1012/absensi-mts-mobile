import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String) onResult;
  final Color borderColor; // Menerima warna dari Parent (ScannerDialog)

  const BarcodeScannerPage({
    super.key,
    required this.onResult,
    required this.borderColor,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  // Controller Scanner
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.front, // Default kamera depan
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode], // Optimasi: Hanya scan QR
    detectionSpeed: DetectionSpeed.normal, // Hemat baterai
  );

  // Debounce lokal untuk mencegah spamming callback ke parent
  String? _lastScanned;
  DateTime _lastScanTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pemindai Absensi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Ganti Kamera',
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. KAMERA SCANNER
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final result = barcodes.first.rawValue;
                final now = DateTime.now();

                // Debounce Lokal: Cegah scan code yg sama dlm 1.5 detik
                if (result != null &&
                    (result != _lastScanned ||
                        now.difference(_lastScanTime).inMilliseconds > 1500)) {
                  _lastScanned = result;
                  _lastScanTime = now;

                  // Kirim hasil ke Parent (ScannerDialog)
                  // Parent yang akan mengubah warna border & proses DB
                  widget.onResult(result);
                }
              }
            },
          ),

          // 2. OVERLAY (GELAP + KOTAK)
          // Menggunakan RepaintBoundary untuk performa
          RepaintBoundary(
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: ScannerOverlayPainter(
                borderColor: widget.borderColor, // Pakai warna dari parent
              ),
            ),
          ),

          // 3. TEKS INSTRUKSI
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Arahkan QR Code ke dalam kotak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pastikan pencahayaan cukup',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // 4. Close Button (Floating)
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// PAINTER UNTUK OVERLAY
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Area Gelap (Background)
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Area Kotak Scan (Bolong)
    final scanWindowSize = 280.0;
    final scanWindowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    final cutOutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindowRect, const Radius.circular(20)),
      );

    // Gabungkan (Background - Kotak)
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutOutPath,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.6) // Gelap transparan
      ..style = PaintingStyle.fill;

    canvas.drawPath(finalPath, backgroundPaint);

    // Gambar Border Kotak (Warna Dinamis)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          5 // Lebih tebal biar jelas
      ..strokeCap = StrokeCap.round;

    // Gambar 4 Sudut (Corner) saja biar keren, atau Full Box
    // Disini kita gambar Full Box Rounded
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindowRect, const Radius.circular(20)),
      borderPaint,
    );

    // Opsional: Tambahkan garis scan animasi di masa depan
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}
