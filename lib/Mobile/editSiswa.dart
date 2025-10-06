import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSiswaScreen extends StatefulWidget {
  final int id;
  final String no;
  final String nama;
  final String? keterangan;

  const EditSiswaScreen({
    super.key,
    required this.id,
    required this.no,
    required this.nama,
    this.keterangan,
  });

  @override
  State<EditSiswaScreen> createState() => _EditSiswaScreenState();
}

class _EditSiswaScreenState extends State<EditSiswaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  String? selectedKeterangan;
  File? selectedFile;

  final picker = ImagePicker();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Atur keterangan awal. Jika null atau kosong, anggap 'Hadir'.
    selectedKeterangan = widget.keterangan ?? "Hadir";
  }

  Future<void> _pickFile(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        selectedFile = File(picked.path);
      });
    }
  }

  /// Fungsi untuk mengirim data dan file ke Supabase
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Siapkan map untuk menampung data yang akan diupdate
      final Map<String, dynamic> dataToUpdate = {
        'keterangan': selectedKeterangan,
      };

      // Tentukan apakah perlu mengunggah file
      bool needsFileUpload =
          selectedKeterangan == 'Sakit' || selectedKeterangan == 'Izin';

      if (selectedFile != null && needsFileUpload) {
        final fileExtension = selectedFile!.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}.$fileExtension';
        final filePath = '${widget.id}/$fileName';

        await _supabase.storage
            .from('surat_keterangan')
            .upload(filePath, selectedFile!);

        final fileUrl = _supabase.storage
            .from('surat_keterangan')
            .getPublicUrl(filePath);

        dataToUpdate['surat_keterangan_url'] = fileUrl;
      } else if (!needsFileUpload) {
        // Jika keterangan diubah menjadi sesuatu yang tidak butuh file (Hadir/Alfa),
        // hapus URL file yang mungkin sudah ada sebelumnya.
        dataToUpdate['surat_keterangan_url'] = null;
      }

      print("Data yang akan diupdate: $dataToUpdate");

      await _supabase.from('siswa').update(dataToUpdate).eq('id', widget.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Data berhasil diperbarui'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print("!!! TERJADI ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Gagal memperbarui data: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah bagian upload harus aktif
    final bool isUploadEnabled =
        selectedKeterangan == 'Sakit' || selectedKeterangan == 'Izin';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Status Siswa"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField("No. Absen", widget.no),
              const SizedBox(height: 20),
              _buildReadOnlyField("Nama Siswa", widget.nama),
              const SizedBox(height: 20),

              // PERUBAHAN: Hanya ada satu dropdown untuk Keterangan
              Text("Keterangan"),
              DropdownButtonFormField<String>(
                value: selectedKeterangan,
                hint: const Text("Pilih keterangan"),
                items: const [
                  DropdownMenuItem(value: "Hadir", child: Text("Hadir")),
                  DropdownMenuItem(value: "Sakit", child: Text("Sakit")),
                  DropdownMenuItem(value: "Izin", child: Text("Izin")),
                  DropdownMenuItem(value: "Alfa", child: Text("Alfa")),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedKeterangan = val;
                    // Jika keterangan baru tidak butuh file, hapus file yang sudah dipilih
                    if (val == 'Hadir' || val == 'Alfa') {
                      selectedFile = null;
                    }
                  });
                },
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                validator: (value) =>
                    value == null ? 'Keterangan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // PERUBAHAN: Form upload surat keterangan sekarang terlihat tapi bisa disabled
              Text(
                "Upload Surat Keterangan",
                style: TextStyle(
                  color: isUploadEnabled ? Colors.black : Colors.grey,
                ),
              ),
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
                          ? "Pilih File dari Galeri"
                          : selectedFile!.path.split('/').last,
                      style: TextStyle(
                        color: isUploadEnabled ? Colors.black : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                  child: Text(
                "Atau",
                style: TextStyle(
                  color: isUploadEnabled ? Colors.black : Colors.grey,
                ),
              )),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploadEnabled
                      ? Colors.green.shade300
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed:
                    isUploadEnabled ? () => _pickFile(ImageSource.camera) : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Buka Kamera & Ambil Foto"),
              ),

              const SizedBox(height: 40),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: isLoading ? null : _submitForm,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3))
                          : const Text("Simpan"),
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

