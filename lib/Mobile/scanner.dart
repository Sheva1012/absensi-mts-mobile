import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  // PERBAIKAN 1: Mengatur kamera default ke kamera depan
  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.front,
  );
  bool _isProcessing = false;

  /// Fungsi ini akan dipanggil setelah barcode terdeteksi
  Future<void> _handleBarcode(BarcodeCapture capture) async {
    // Hentikan proses jika sedang memproses barcode sebelumnya
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Ambil nilai dari barcode pertama yang terdeteksi
    final String? scannedValue = capture.barcodes.first.rawValue;

    if (scannedValue == null) {
      _showErrorAndResume('Barcode tidak valid.');
      return;
    }

    print("Barcode terdeteksi: $scannedValue");

    // Tampilkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // --- TODO: LOGIKA ABSENSI ANDA DI SINI ---
      // Contoh: Perbarui status siswa di database berdasarkan hasil scan
      // final siswaId = int.tryParse(scannedValue);
      // if (siswaId != null) {
      //   await Supabase.instance.client
      //       .from('siswa')
      //       .update({'keterangan': 'Hadir'})
      //       .eq('id', siswaId);
      // } else {
      //   throw Exception('Format barcode tidak valid.');
      // }
      // ------------------------------------------
      
      // Simulasi proses
      await Future.delayed(const Duration(seconds: 2));

      // Tutup dialog loading
      Navigator.of(context, rootNavigator: true).pop();

      // Kembali ke halaman sebelumnya dan kirim hasil scan
      Navigator.pop(context, scannedValue);

    } catch (e) {
      // Tutup dialog loading jika terjadi error
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorAndResume('Gagal memproses absensi: ${e.toString()}');
    }
  }

  void _showErrorAndResume(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    // Lanjutkan scanning setelah error
    setState(() {
      _isProcessing = false;
    });
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemindai Barcode'),
        backgroundColor: const Color(0xFF2F6CB0),
        foregroundColor: Colors.white,
        // Tombol untuk mengganti kamera (opsional tapi berguna)
        actions: [
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: "Ganti Kamera",
          )
        ],
      ),
      body: Stack(
        children: [
          // Widget utama untuk menampilkan kamera scanner
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),

          // Overlay kustom untuk area pemindaian
          _buildScannerOverlay(context),
        ],
      ),
    );
  }

  /// Widget untuk membuat overlay gelap dengan lubang di tengah
  Widget _buildScannerOverlay(BuildContext context) {
    // PERBAIKAN 2: Memperlebar area pindai
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 300,  // Lebih lebar
      height: 300, // Lebih pendek (persegi panjang)
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: scanWindow.top,
                left: scanWindow.left,
                child: Container(
                  width: scanWindow.width,
                  height: scanWindow.height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Teks petunjuk di bawah area pemindaian
        Positioned(
          top: scanWindow.bottom + 20,
          left: 0,
          right: 0,
          child: const Text(
            'Posisikan barcode di dalam kotak',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

