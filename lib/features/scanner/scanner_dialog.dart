import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../data/repositories/repositories.dart';
import 'scanner_widget.dart';

/// Scanner dialog with continuous scanning and attendance processing
class ContinuousScannerDialog extends StatefulWidget {
  const ContinuousScannerDialog({super.key});

  @override
  State<ContinuousScannerDialog> createState() =>
      _ContinuousScannerDialogState();
}

class _ContinuousScannerDialogState extends State<ContinuousScannerDialog> {
  final SiswaRepository _siswaRepository = SiswaRepository();
  final AbsensiRepository _absensiRepository = AbsensiRepository();

  bool _isProcessing = false;
  String? _lastScan;
  DateTime _lastScanTime = DateTime.now();
  Color _borderColor = Colors.red;

  void _showToast(String message, {Color color = Colors.green}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _handleScan(String result) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    // Debounce: Prevent scanning same code within 2 seconds
    if (result == _lastScan &&
        now.difference(_lastScanTime).inMilliseconds < UiConstants.scanDebounceMs) {
      return;
    }

    _lastScan = result;
    _lastScanTime = now;

    setState(() {
      _isProcessing = true;
      _borderColor = Colors.yellow; // Loading color
    });

    try {
      // Find student by NIS (QR code content)
      final siswaData = await _siswaRepository.findForScan(result);

      if (siswaData == null) {
        throw StudentNotFoundException(
          message: 'Siswa tidak ditemukan',
          nis: result,
        );
      }

      // Process attendance
      final absensiResult = await _absensiRepository.processCheckIn(
        siswaId: siswaData.id,
        namaSiswa: siswaData.nama,
        kelasId: siswaData.kelasId,
      );

      if (mounted) {
        setState(() {
          _borderColor = absensiResult.success
              ? (absensiResult.isCheckIn
                  ? (absensiResult.isLate ? Colors.orange : Colors.green)
                  : Colors.blue)
              : Colors.orange;
        });
      }

      _showToast(
        absensiResult.message,
        color: absensiResult.success
            ? (absensiResult.isLate ? Colors.orange : Colors.green)
            : Colors.orange,
      );
    } on StudentNotFoundException catch (e) {
      if (mounted) setState(() => _borderColor = Colors.red);
      _showToast('❌ NIS Tidak Terdaftar: ${e.nis ?? result}', color: Colors.red);
    } on AttendanceException catch (e) {
      if (mounted) setState(() => _borderColor = Colors.red);
      _showToast('❌ ${e.message}', color: Colors.red);
    } catch (e) {
      if (mounted) setState(() => _borderColor = Colors.red);
      _showToast('❌ Error: $e', color: Colors.red);
    } finally {
      // Delay to show status color before resetting
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _borderColor = Colors.red; // Standby color
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerPage(
      onResult: _handleScan,
      borderColor: _borderColor,
    );
  }
}
