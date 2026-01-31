import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSiswaLogic extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  File? selectedFile;

  // Method untuk memilih gambar
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Kompresi kualitas gambar
        maxWidth: 1024, // Resize gambar agar tidak terlalu besar
      );

      if (picked != null) {
        selectedFile = File(picked.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error pick image: $e");
    }
  }

  // Method Utama: Simpan Data
  Future<bool> submitAbsensi({
    required int siswaId,
    required DateTime tanggal,
    required String status,
    String? oldSuratUrl, // URL surat lama (jika ada)
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final tanggalStr = tanggal.toIso8601String().split('T').first;
      String? finalSuratUrl = oldSuratUrl;

      // 1. Logic Upload File (Hanya jika status Izin/Sakit)
      final bool isButuhSurat = (status == 'izin' || status == 'sakit');

      if (isButuhSurat && selectedFile != null) {
        // Upload file baru
        final ext = selectedFile!.path.split('.').last;
        final fileName = '${siswaId}_$tanggalStr.$ext';
        final filePath = 'absensi/$fileName'; // Path storage

        await _supabase.storage
            .from('surat_keterangan')
            .upload(
              filePath,
              selectedFile!,
              fileOptions: const FileOptions(upsert: true),
            );

        finalSuratUrl = _supabase.storage
            .from('surat_keterangan')
            .getPublicUrl(filePath);
      } else if (!isButuhSurat) {
        // Jika status berubah jadi Hadir/Alfa/Terlambat, hapus referensi surat
        finalSuratUrl = null;
        // Opsional: Hapus file fisik di storage jika perlu menghemat space
      }

      // 2. Persiapkan Data DB
      final Map<String, dynamic> data = {
        'siswa_id': siswaId,
        'tanggal': tanggalStr,
        'status': status,
        'surat_url': finalSuratUrl, // Bisa null
        'updated_at': DateTime.now().toIso8601String(),
        // 'updated_by': _supabase.auth.currentUser?.id, // Uncomment jika ada kolom ini
      };

      // 3. Upsert (Insert atau Update jika sudah ada)
      // Supabase v2 support .upsert() yang lebih ringkas daripada cek exist manual
      await _supabase
          .from('absensi')
          .upsert(
            data,
            onConflict:
                'siswa_id, tanggal', // Kolom unik untuk deteksi duplikat
          );

      return true; // Sukses
    } catch (e) {
      debugPrint("Error Submit: $e");
      return false; // Gagal
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
