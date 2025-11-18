import 'dart:async'; // Import untuk menggunakan Timer
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String) onResult;
  final Color borderColor;

  const BarcodeScannerPage({super.key, required this.onResult, required this.borderColor});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.front,
    torchEnabled: false,
  );

  String? _lastScanned;
  DateTime _lastScanTime = DateTime.now();
  
  // PERBAIKAN: Tambahkan state untuk warna border
  Color _borderColor = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemindai Barcode'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Ganti Kamera',
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Tutup',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final result = barcodes.first.rawValue;
                final now = DateTime.now();
                if (result != null &&
                    (result != _lastScanned ||
                        now.difference(_lastScanTime).inMilliseconds > 2000)) { // Tambah jeda
                  _lastScanned = result;
                  _lastScanTime = now;
                  
                  // PERBAIKAN: Ubah warna menjadi hijau saat scan berhasil
                  setState(() {
                    _borderColor = Colors.greenAccent;
                  });

                  widget.onResult(result);

                  // Kembalikan warna ke merah setelah 2 detik
                  Timer(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _borderColor = Colors.red;
                      });
                    }
                  });
                }
              }
            },
          ),
          
          CustomPaint(
            size: MediaQuery.of(context).size,
            // PERBAIKAN: Kirim state warna ke painter
            painter: ScannerOverlayPainter(borderColor: _borderColor),
          ),

          const Center(
            child: SizedBox(
              width: 260,
              height: 260,
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              '📷 Arahkan QR ke dalam kotak\nScanner aktif terus-menerus',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
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

// Class baru untuk menggambar overlay
class ScannerOverlayPainter extends CustomPainter {
  // PERBAIKAN: Terima warna border sebagai parameter
  final Color borderColor;
  ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final scanWindowRect = Rect.fromCenter(
      center: screenRect.center,
      width: 260,
      height: 260,
    );
    final scanWindowRRect = RRect.fromRectAndRadius(scanWindowRect, const Radius.circular(16));

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.8);
    final borderPaint = Paint()
      // PERBAIKAN: Gunakan warna dari parameter
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cutOutPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screenRect),
      Path()..addRRect(scanWindowRRect),
    );
    
    canvas.drawPath(cutOutPath, backgroundPaint);
    canvas.drawRRect(scanWindowRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    // Repaint jika warna border berubah
    return oldDelegate.borderColor != borderColor;
  }
}

