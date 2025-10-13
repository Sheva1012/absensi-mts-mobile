import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSiswaScreen extends StatefulWidget {
  final int id;
  final String no;
  final String nama;
  final String? suratUrl;

  const EditSiswaScreen({
    super.key,
    required this.id,
    required this.no,
    required this.nama,
    this.suratUrl,
  });

  @override
  State<EditSiswaScreen> createState() => _EditSiswaScreenState();
}

class _EditSiswaScreenState extends State<EditSiswaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final picker = ImagePicker();

  String? selectedStatus;
  File? selectedFile;
  bool isLoading = false;
  bool isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadAbsensiStatus();
  }

  /// Ambil status absensi hari ini dari DB
  Future<void> _loadAbsensiStatus() async {
    final tanggalOnly = DateTime.now().toIso8601String().split('T').first;

    final existingAbsensi = await _supabase
        .from('absensi')
        .select()
        .eq('siswa_id', widget.id)
        .eq('tanggal', tanggalOnly)
        .maybeSingle();

    setState(() {
      if (existingAbsensi != null) {
        selectedStatus = _capitalize(existingAbsensi['status'] ?? 'alfa');
      } else {
        selectedStatus = 'Alfa'; // Default kalau belum ada absen
      }
      isLoadingStatus = false;
    });
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
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

      // Cek apakah absensi hari ini sudah ada
      final existingAbsensi = await _supabase
          .from('absensi')
          .select()
          .eq('siswa_id', widget.id)
          .eq('tanggal', tanggalOnly)
          .maybeSingle();

      if (existingAbsensi != null) {
        // Sudah ada → update status
        await _supabase
            .from('absensi')
            .update({
              'status': selectedStatus?.toLowerCase() ?? 'alfa',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingAbsensi['id']);
      } else {
        // Belum ada → insert baru (validasi manual oleh guru)
        await _supabase.from('absensi').insert({
          'siswa_id': widget.id,
          'tanggal': tanggalOnly,
          'status': selectedStatus?.toLowerCase() ?? 'alfa',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Proses surat jika sakit/izin
      final bool needsSurat =
          selectedStatus == 'Sakit' || selectedStatus == 'Izin';

      if (needsSurat && selectedFile != null) {
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

        await _supabase.from('surat').upsert({
          'siswa_id': widget.id,
          'tanggal': tanggalOnly,
          'file_url': fileUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase.from('surat').delete().match({
          'siswa_id': widget.id,
          'tanggal': tanggalOnly,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Status absensi berhasil diperbarui'),
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
    if (isLoadingStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isUploadEnabled =
        selectedStatus == 'Sakit' || selectedStatus == 'Izin';

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

              const Text('Status Absensi'),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'Izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'Alfa', child: Text('Alfa')),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedStatus = val;
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

              Text(
                'Upload Surat Keterangan',
                style: TextStyle(
                  color: isUploadEnabled ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap:
                    isUploadEnabled ? () => _pickFile(ImageSource.gallery) : null,
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
                        color:
                            isUploadEnabled ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
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
