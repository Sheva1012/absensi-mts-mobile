import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'absensi_controller.dart'; 

// 1. WIDGET HALAMAN UTAMA UNTUK EDIT/INPUT ABSENSI (WEB/DESKTOP)
class EditAbsensiWebScreen extends StatefulWidget {
  final AbsensiController controller;
  final Map<String, dynamic> absensiData; // Data baris yang dipilih

  const EditAbsensiWebScreen({
    super.key,
    required this.controller,
    required this.absensiData,
  });

  @override
  State<EditAbsensiWebScreen> createState() => _EditAbsensiWebScreenState();
}

class _EditAbsensiWebScreenState extends State<EditAbsensiWebScreen> {
  final _formKey = GlobalKey<FormState>();

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