import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSiswaScreen extends StatefulWidget {
  final int id;
  final String no;
  final String nama;
  final String? keterangan;
  final String? suratUrl;

  const EditSiswaScreen({
    super.key,
    required this.id,
    required this.no,
    required this.nama,
    this.keterangan,
    this.suratUrl,
  });

  @override
  State<EditSiswaScreen> createState() => _EditSiswaScreenState();
}

class _EditSiswaScreenState extends State<EditSiswaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final picker = ImagePicker();

  String? selectedKeterangan;
  File? selectedFile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Gunakan nilai dari widget, default ke 'Alfa' jika null
    selectedKeterangan = widget.keterangan ?? 'Alfa';

    if (selectedKeterangan != null) {
      selectedKeterangan = selectedKeterangan![0].toUpperCase() + selectedKeterangan!.substring(1).toLowerCase();
    }
  }

  Future<void> _pickFile(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => selectedFile = File(picked.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final tanggalOnly = DateTime.now().toIso8601String().split('T').first;

      // === 1. PROSES TABEL ABSENSI (Menggunakan Upsert) ===
      await _supabase.from('absensi').upsert({
        'siswa_id': widget.id,
        'tanggal': tanggalOnly,
        'status': selectedKeterangan?.toLowerCase(), // Simpan sebagai lowercase
      }, onConflict: 'siswa_id, tanggal');

      // === 2. PROSES TABEL SURAT ===
      final bool needsSurat =
          selectedKeterangan == 'Sakit' || selectedKeterangan == 'Izin';

      if (needsSurat) {
        if (selectedFile != null) {
          final ext = selectedFile!.path.split('.').last;
          final fileName = '${widget.id}_$tanggalOnly.$ext';
          final filePath = 'surat_izin/${widget.id}/$fileName';

          await _supabase.storage
              .from('surat_keterangan')
              .upload(
                filePath,
                selectedFile!,
                fileOptions: const FileOptions(upsert: true),
              );

          final fileUrl = _supabase.storage
              .from('surat_keterangan')
              .getPublicUrl(filePath);

          // PERBAIKAN: Tambahkan 'jenis' saat menyimpan ke tabel 'surat'
          await _supabase.from('surat').upsert({
            'siswa_id': widget.id,
            'tanggal': tanggalOnly,
            'file_url': fileUrl,
            'jenis': selectedKeterangan
                ?.toLowerCase(), // <-- TAMBAHKAN BARIS INI
          }, onConflict: 'siswa_id, tanggal');
        }
      } else {
        // Jika statusnya Hadir/Alfa, hapus data surat yang mungkin ada
        await _supabase.from('surat').delete().match({
          'siswa_id': widget.id,
          'tanggal': tanggalOnly,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Status absensi berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ ERROR saat simpan absensi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan absensi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUploadEnabled =
        selectedKeterangan == 'Sakit' || selectedKeterangan == 'Izin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validasi Absensi Siswa'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField('No. Absen', widget.no),
              const SizedBox(height: 20),
              _buildReadOnlyField('Nama Siswa', widget.nama),
              const SizedBox(height: 20),
              const Text('Keterangan Absensi'),
              DropdownButtonFormField<String>(
                value: selectedKeterangan,
                items: const [
                  DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'Izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'Alfa', child: Text('Alfa')),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedKeterangan = val;
                    if (val == 'Hadir' || val == 'Alfa') {
                      selectedFile = null;
                    }
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) =>
                    v == null ? 'Status tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              if (widget.suratUrl != null && selectedFile == null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.suratUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Text('Gagal memuat gambar surat'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Surat keterangan sebelumnya',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              Text(
                'Upload Surat Keterangan',
                style: TextStyle(
                  color: isUploadEnabled ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isUploadEnabled
                    ? () => _pickFile(ImageSource.gallery)
                    : null,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: isUploadEnabled
                        ? Colors.grey.shade100
                        : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: Text(
                      selectedFile == null
                          ? 'Pilih file dari galeri'
                          : selectedFile!.path.split('/').last,
                      style: TextStyle(
                        color: isUploadEnabled
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text('Atau')),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploadEnabled ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: isUploadEnabled
                    ? () => _pickFile(ImageSource.camera)
                    : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ambil Foto'),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading ? null : _submitForm,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            fillColor: Colors.grey.shade200,
            filled: true,
          ),
        ),
      ],
    );
  }
}
