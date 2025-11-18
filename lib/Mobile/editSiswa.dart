import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSiswaScreen extends StatefulWidget {
  final int id;
  final String no;
  final String nama;
  final String? keterangan;
  final String? suratUrl;

  const EditAbsensiWebScreen({
    super.key,
    required this.id,
    required this.no,
    required this.nama,
    this.keterangan,
    this.suratUrl,
    required this.controller,
    required this.absensiData,
  });

  @override
  State<EditAbsensiWebScreen> createState() => _EditAbsensiWebScreenState();
}

class _EditAbsensiWebScreenState extends State<EditAbsensiWebScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final picker = ImagePicker();

  String? selectedKeterangan;
  File? selectedFile;
  bool isLoading = false;

  // State LOKAL untuk form
  late String selectedStatus;
  late DateTime selectedTanggal;
  late TextEditingController keteranganController;
  TimeOfDay? waktuMasuk;
  TimeOfDay? waktuPulang;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Gunakan nilai dari widget, default ke 'Alfa' jika null
    selectedKeterangan = widget.keterangan ?? 'Alfa';
  }

  Future<void> _pickFile(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => selectedFile = File(picked.path));
    final a = widget.absensiData;
    final controller = widget.controller;

    // PERUBAHAN: Set default status ke 'alfa' jika status absen belum ada.
    // Ini meniru logika di mana ketidakhadiran default adalah Alfa, sesuai permintaan.
    selectedStatus = a['status'] ?? 'alfa';
    selectedTanggal = controller.parseDateTime(a['tanggal']) ?? controller.selectedDate;
    waktuMasuk = controller.parseTimeOfDay(a['waktu_masuk']);
    waktuPulang = controller.parseTimeOfDay(a['waktu_pulang']);
    keteranganController = TextEditingController(text: a['keterangan'] ?? '');
  }

  @override
  void dispose() {
    keteranganController.dispose();
    super.dispose();
  }
  
  // Helper untuk Date Picker
  Future<void> _pickDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: selectedTanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        selectedTanggal = newDate;
      });
    }
  }

  // Helper untuk Time Picker
  Future<void> _pickTime(bool isMasuk) async {
    final initialTime = (isMasuk ? waktuMasuk : waktuPulang) ?? TimeOfDay.now();
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null) {
      setState(() {
        if (isMasuk) {
          waktuMasuk = newTime;
        } else {
          waktuPulang = newTime;
        }
      });
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
  // Logika Simpan (Create vs Update)
  Future<void> _saveChanges() async {
    if(!_formKey.currentState!.validate()) return;
    
    setState(() => isSaving = true);

    final dynamic absensiId = widget.absensiData['id'];
    // Siswa ID pasti ada, diambil dari data siswa atau properti siswa_id
    final int siswaId = widget.absensiData['siswa_id'] ?? 
                        widget.absensiData['siswa']['id'];

    try {
      if (absensiId == null) {
        // CREATE
        await widget.controller.createAbsensi(
          siswaId: siswaId,
          status: selectedStatus,
          keterangan: keteranganController.text,
          waktuMasuk: waktuMasuk,
          waktuPulang: waktuPulang,
          tanggal: selectedTanggal,
        );
      } else {
        // UPDATE
        await widget.controller.updateAbsensi(
          absensiId: absensiId as int,
          status: selectedStatus,
          keterangan: keteranganController.text,
          waktuMasuk: waktuMasuk,
          waktuPulang: waktuPulang,
          tanggal: selectedTanggal,
        );
      }

      if (mounted) {
        // Pop screen dan kirim 'true' untuk memberitahu page sebelumnya agar refresh
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data absensi berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan data: $e'),
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

      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // Helper: MEREPLIKASI LAYOUT _buildReadOnlyField (untuk form non-text)
  Widget _buildField({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isClearable = false,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isClearable && onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: const Icon(Icons.clear, size: 20, color: Colors.red),
                  ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper: Read Only Field (Sama persis dengan EditSiswaScreen)
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          readOnly: true,
          style: const TextStyle(fontSize: 15, color: Colors.black),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            fillColor: Colors.grey.shade200,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.absensiData;
    final namaSiswa = (a['siswa'] is Map) ? (a['siswa']['nama'] ?? '-') : '-';
    final noAbsen = (a['siswa'] is Map) ? (a['siswa']['no_absen'] ?? '-') : '-';

    final double maxContentWidth = 500; // Lebar maksimal yang ideal untuk formulir mobile-style

    return Scaffold(
      appBar: AppBar(
        title: Text(
          a['id'] == null 
          ? 'Input Absensi: $namaSiswa'
          : 'Edit Absensi: $namaSiswa',
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Formulir Edit Absensi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 30),

                  // Bidang Read-Only
                  _buildReadOnlyField('No. Absen', noAbsen),
                  const SizedBox(height: 20),
                  _buildReadOnlyField('Nama Siswa', namaSiswa),
                  const SizedBox(height: 20),

                  // Form Status
                  const Text('Status Absensi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: ['hadir', 'terlambat', 'sakit', 'izin', 'alfa']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              '${status[0].toUpperCase()}${status.substring(1)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedStatus = value);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    ),
                    validator: (v) => v == null ? 'Pilih status' : null,
                  ),
                  const SizedBox(height: 20),

                  // Form Tanggal (Menggunakan replikasi ReadOnlyField style)
                  _buildField(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal',
                    value: DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedTanggal),
                    iconColor: Colors.blue,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 20),

                  // Form Waktu Masuk
                  _buildField(
                    icon: Icons.login,
                    label: 'Waktu Masuk',
                    value: waktuMasuk?.format(context) ?? 'Belum diatur',
                    iconColor: Colors.green,
                    onTap: () => _pickTime(true),
                    isClearable: waktuMasuk != null,
                    onClear: () => setState(() => waktuMasuk = null),
                  ),
                  const SizedBox(height: 20),

                  // Form Waktu Pulang
                  _buildField(
                    icon: Icons.logout,
                    label: 'Waktu Pulang',
                    value: waktuPulang?.format(context) ?? 'Belum diatur',
                    iconColor: Colors.red,
                    onTap: () => _pickTime(false),
                    isClearable: waktuPulang != null,
                    onClear: () => setState(() => waktuPulang = null),
                  ),
                  const SizedBox(height: 20),

                  // Form Keterangan
                  const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: keteranganController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan tambahan (misal: alasan sakit)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // Tombol Aksi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: isSaving ? null : _saveChanges,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}