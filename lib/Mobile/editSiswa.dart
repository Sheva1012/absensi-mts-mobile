import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'editSiswa_logic.dart'; // Import Logic

class EditSiswaScreen extends StatelessWidget {
  final int siswaId;
  final String no;
  final String nama;
  final DateTime tanggal;
  final String? statusAwal; // Rename biar jelas ini data awal
  final String? suratUrl;

  const EditSiswaScreen({
    super.key,
    required this.siswaId,
    required this.no,
    required this.nama,
    required this.tanggal,
    this.statusAwal, // Rename parameter di constructor juga
    this.suratUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditSiswaLogic(),
      child: _EditSiswaForm(
        siswaId: siswaId,
        no: no,
        nama: nama,
        tanggal: tanggal,
        statusAwal: statusAwal,
        suratUrl: suratUrl,
      ),
    );
  }
}

class _EditSiswaForm extends StatefulWidget {
  final int siswaId;
  final String no;
  final String nama;
  final DateTime tanggal;
  final String? statusAwal;
  final String? suratUrl;

  const _EditSiswaForm({
    required this.siswaId,
    required this.no,
    required this.nama,
    required this.tanggal,
    this.statusAwal,
    this.suratUrl,
  });

  @override
  State<_EditSiswaForm> createState() => _EditSiswaFormState();
}

class _EditSiswaFormState extends State<_EditSiswaForm> {
  final _formKey = GlobalKey<FormState>();
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    // Default status jika null adalah 'hadir'
    selectedStatus = widget.statusAwal?.toLowerCase() ?? 'hadir';
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<EditSiswaLogic>();

    // Cek apakah butuh upload (Sakit/Izin)
    final bool isButuhSurat =
        (selectedStatus == 'sakit' || selectedStatus == 'izin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validasi Absensi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Siswa Readonly
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Dropdown Status
              const Text(
                "Status Kehadiran",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir ✅')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit 🏥')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin ✉️')),
                  DropdownMenuItem(value: 'alpha', child: Text('Alpha ❌')),
                  DropdownMenuItem(
                    value: 'terlambat',
                    child: Text('Terlambat ⏰'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Area Upload Surat (Kondisional)
              AnimatedOpacity(
                opacity: isButuhSurat ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring:
                      !isButuhSurat, // Disable klik jika tidak butuh surat
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Lampiran Surat (Opsional)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Preview Gambar (File Baru atau URL Lama)
                      if (logic.selectedFile != null)
                        _buildFilePreview(logic.selectedFile!)
                      else if (widget.suratUrl != null &&
                          widget.suratUrl!.isNotEmpty)
                        _buildUrlPreview(widget.suratUrl!)
                      else
                        _buildUploadPlaceholder(),

                      const SizedBox(height: 12),

                      // Tombol Aksi Kamera/Galeri
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  logic.pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Kamera"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  logic.pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text("Galeri"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: logic.isLoading
                      ? null
                      : () async {
                          final success = await logic.submitAbsensi(
                            siswaId: widget.siswaId,
                            tanggal: widget.tanggal,
                            status: selectedStatus,
                            oldSuratUrl: widget.suratUrl,
                          );

                          if (!mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Berhasil disimpan!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(
                              context,
                              true,
                            ); // Kembali dengan result true (refresh)
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menyimpan data.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: logic.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SIMPAN PERUBAHAN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final tglStr = widget.tanggal.toIso8601String().split('T')[0];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          _infoRow("Nama Siswa", widget.nama),
          const Divider(),
          _infoRow("Nomor Absen", widget.no),
          const Divider(),
          _infoRow("Tanggal Absensi", tglStr),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFilePreview(File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildUrlPreview(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Text(
              "Gagal memuat gambar",
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text("Belum ada lampiran", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
