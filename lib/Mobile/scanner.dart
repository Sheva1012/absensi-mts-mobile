import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  final void Function(String) onResult;

  const BarcodeScannerPage({super.key, required this.onResult});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    torchEnabled: false,
    returnImage: false,
  );

  String? _lastScanned; // mencegah pembacaan dobel terlalu cepat
  DateTime _lastScanTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === Kamera aktif terus ===
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final result = barcodes.first.rawValue;

                // Cegah double-scan dalam waktu < 1 detik
                final now = DateTime.now();
                if (result != null &&
                    (result != _lastScanned ||
                        now.difference(_lastScanTime).inMilliseconds > 1000)) {
                  _lastScanned = result;
                  _lastScanTime = now;
                  widget.onResult(result);
                }
              }
            },
          ),

          // === Kotak Border Panduan ===
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.greenAccent,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // === Overlay teks panduan ===
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              '📷 Arahkan QR ke dalam kotak\nScanner aktif terus-menerus',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // === Tombol Tutup (opsional) ===
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
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
