import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSiswaScreen extends StatefulWidget {
  final int siswaId;
  final String no;
  final String nama;
  final DateTime tanggal;
  final String? status;
  final String? suratUrl;

  const EditSiswaScreen({
    super.key,
    required this.siswaId,
    required this.no,
    required this.nama,
    required this.tanggal,
    this.status,
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

  @override
  void initState() {
    super.initState();
    // enum PostgreSQL lowercase
    selectedStatus = widget.status?.toLowerCase() ?? 'hadir';
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
      final tanggalOnly = widget.tanggal.toIso8601String().split('T').first;

      final Map<String, dynamic> dataToSave = {
        'siswa_id': widget.siswaId,
        'tanggal': tanggalOnly,
        'status': selectedStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final bool needsFileUpload =
          selectedStatus == 'sakit' || selectedStatus == 'izin';

      // === Upload / hapus surat ===
      if (needsFileUpload) {
        if (selectedFile != null) {
          final ext = selectedFile!.path.split('.').last;
          final fileName = '${widget.siswaId}_$tanggalOnly.$ext';
          final filePath = 'absensi/${widget.siswaId}/$fileName';

          await _supabase.storage.from('surat_keterangan').upload(
                filePath,
                selectedFile!,
                fileOptions: const FileOptions(upsert: true),
              );

          final fileUrl =
              _supabase.storage.from('surat_keterangan').getPublicUrl(filePath);
          dataToSave['surat_url'] = fileUrl;
        } else {
          dataToSave['surat_url'] = widget.suratUrl;
        }
      } else {
        // hadir / alpha / terlambat
        dataToSave['surat_url'] = null;
        dataToSave['keterangan'] = null;
      }

      // === cek apakah absensi sudah ada ===
      final existing = await _supabase
          .from('absensi')
          .select('id')
          .eq('siswa_id', widget.siswaId)
          .eq('tanggal', tanggalOnly)
          .maybeSingle();

      if (existing == null) {
        // belum ada → insert baru
        await _supabase.from('absensi').insert(dataToSave);
      } else {
        // sudah ada → update
        await _supabase
            .from('absensi')
            .update(dataToSave)
            .eq('siswa_id', widget.siswaId)
            .eq('tanggal', tanggalOnly);
      }

      // ambil ulang data terbaru dari Supabase agar form ikut berubah
      final updated = await _supabase
          .from('absensi')
          .select('status, surat_url')
          .eq('siswa_id', widget.siswaId)
          .eq('tanggal', tanggalOnly)
          .maybeSingle();

      if (updated != null) {
        setState(() {
          selectedStatus = updated['status'];
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Status absensi berhasil disimpan'),
        backgroundColor: Colors.green,
      ));

      // kirim sinyal ke halaman sebelumnya untuk refresh
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ ERROR saat simpan absensi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Gagal menyimpan absensi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUploadEnabled =
        selectedStatus == 'sakit' || selectedStatus == 'izin';

    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Absensi Siswa'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildReadOnlyField('No. Absen', widget.no),
            const SizedBox(height: 20),
            _buildReadOnlyField('Nama Siswa', widget.nama),
            const SizedBox(height: 20),
            _buildReadOnlyField(
                'Tanggal', widget.tanggal.toIso8601String().split('T').first),
            const SizedBox(height: 20),
            const Text('Status Kehadiran'),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
                DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
              ],
              onChanged: (val) {
                setState(() {
                  selectedStatus = val;
                  if (val == 'hadir' || val == 'alpha' || val == 'terlambat') {
                    selectedFile = null;
                  }
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (v) => v == null ? 'Status tidak boleh kosong' : null,
            ),
            const SizedBox(height: 20),

            // === preview surat lama ===
            if (widget.suratUrl != null && widget.suratUrl!.isNotEmpty)
              Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.suratUrl!,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child:
                          const Center(child: Text('Gambar surat tidak tersedia')),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Surat keterangan sebelumnya',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
              ]),

            Text('Upload Surat Keterangan',
                style: TextStyle(
                    color: isUploadEnabled ? Colors.black : Colors.grey)),
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
                        color: isUploadEnabled ? Colors.black : Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('Atau')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isUploadEnabled ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed:
                  isUploadEnabled ? () => _pickFile(ImageSource.camera) : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto'),
            ),
            const SizedBox(height: 40),

            Row(children: [
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
                              color: Colors.white, strokeWidth: 3))
                      : const Text('Simpan'),
                ),
              ),
            ])
          ]),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
  }
}
