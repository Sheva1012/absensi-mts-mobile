import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editSiswa.dart';

class Absensi {
  final String status; // 'Hadir', 'Sakit', 'Izin', 'Alfa', 'Terlambat'
  final String? tanggal;
  final String? fileUrlSurat;
  final String? jenisSurat;
  final String? statusVerifikasi;

  Absensi({
    required this.status,
    this.tanggal,
    this.fileUrlSurat,
    this.jenisSurat,
    this.statusVerifikasi,
  });
}

class Siswa {
  final int id;
  final int no;
  final String nama;
  final String statusSiswa;
  final Absensi absensiHariIni;
  final String? suratUrlHariIni;

  Siswa({
    required this.id,
    required this.no,
    required this.nama,
    required this.statusSiswa,
    required this.absensiHariIni,
    this.suratUrlHariIni,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    final absensiList = json['absensi'] as List<dynamic>? ?? [];
    final suratList = json['surat'] as List<dynamic>? ?? [];
    final today = DateTime.now().toIso8601String().split('T').first;

    final absensiTodayMap = absensiList
        .cast<Map<String, dynamic>?>()
        .firstWhere((a) => a?['tanggal'] == today, orElse: () => null);

    final suratTodayMap = suratList.cast<Map<String, dynamic>?>().firstWhere(
      (s) => s?['tanggal'] == today,
      orElse: () => null,
    );

    final absensi = Absensi(
      status: _capitalize(absensiTodayMap?['status'] ?? 'Alfa'),
      tanggal: absensiTodayMap?['tanggal'],
    );

    final suratUrl = suratTodayMap?['file_url'] as String?;

    return Siswa(
      id: json['id'] ?? 0,
      no: json['no'] ?? 0,
      nama: json['nama'] ?? 'Tanpa Nama',
      statusSiswa: json['status'] ?? 'aktif',
      absensiHariIni: absensi,
      suratUrlHariIni: suratUrl,
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

/// =======================
/// SCREEN: KELAS
/// =======================

class KelasScreen extends StatefulWidget {
  final String namaKelas;

  const KelasScreen({super.key, required this.namaKelas});

  @override
  State<KelasScreen> createState() => _KelasScreenState();
}

class _KelasScreenState extends State<KelasScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Siswa> _originalSiswaList = [];
  List<Siswa> _filteredSiswaList = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterSiswa);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSiswa);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _filterSiswa() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSiswaList = _originalSiswaList;
      } else {
        _filteredSiswaList = _originalSiswaList
            .where((siswa) => siswa.nama.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  /// ✅ Ambil semua siswa + absensi + surat
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final kelasResponse = await _supabase
          .from('kelas')
          .select('id')
          .eq('nama_kelas', widget.namaKelas)
          .maybeSingle();

      if (kelasResponse == null || kelasResponse['id'] == null) {
        throw Exception(
          "Kelas '${widget.namaKelas}' tidak ditemukan di database.",
        );
      }

      final kelasId = kelasResponse['id'];

      // Ambil data absensi dan surat dengan kolom yang benar
      final data = await _supabase
          .from('siswa')
          .select(
            'id, no, nama, status, absensi(status, tanggal), surat(file_url, tanggal)',
          )
          .eq('kelas_id', kelasId)
          .order('no', ascending: true);

      if (!mounted) return;

      setState(() {
        _originalSiswaList = (data as List<dynamic>)
            .map((item) => Siswa.fromJson(item))
            .toList();
        _filteredSiswaList = _originalSiswaList;
      });
    } catch (e) {
      if (!mounted) return;
      print("!!! ERROR saat fetchData: $e");
      setState(
        () => _errorMessage = e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    _searchController.clear();
    await _fetchData();
  }

  void _navigateToEdit(Siswa siswa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSiswaScreen(
          id: siswa.id,
          no: siswa.no.toString(),
          nama: siswa.nama,
          // status: siswa.absensiHariIni.status,  // HAPUS BARIS INI
          suratUrl: siswa.suratUrlHariIni,
        ),
      ),
    ).then((isSuccess) {
      if (isSuccess == true) {
        _handleRefresh();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Data ${siswa.nama} berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
      }
    });
  }

  /// =======================
  /// UI SECTION
  /// =======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.namaKelas),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 20),
                            _buildTableHeader(),
                          ],
                        ),
                      ),
                    ),
                    _buildSliverBody(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBody() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "😢 Gagal Memuat Data",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleRefresh,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredSiswaList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            _searchController.text.isEmpty
                ? "Tidak ada data siswa."
                : "Siswa '${_searchController.text}' tidak ditemukan.",
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: _filteredSiswaList.length,
        itemBuilder: (context, index) =>
            _buildTableRow(_filteredSiswaList[index]),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  Widget _buildTableRow(Siswa siswa) {
    // --- BARU: Cek apakah status siswa 'Terlambat' ---
    final bool isTerlambat =
        siswa.absensiHariIni.status.toLowerCase() == 'terlambat';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _TableCell(siswa.no.toString(), flex: 1),
          _TableCell(siswa.nama, flex: 3, isName: true),
          // Kolom ini akan otomatis menampilkan "Terlambat" jika itu statusnya
          _TableCell(siswa.absensiHariIni.status, flex: 3),
          Expanded(
            flex: 2,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  // --- BARU: Beri warna berbeda jika tombol nonaktif ---
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                // --- DIUBAH: Set 'onPressed' menjadi null jika terlambat ---
                onPressed: isTerlambat ? null : () => _navigateToEdit(siswa),
                child: const Text('Edit'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama siswa...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _searchController.clear(),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          _TableHeaderCell('No', flex: 1),
          _TableHeaderCell('Nama', flex: 3),
          _TableHeaderCell('Status', flex: 3),
          _TableHeaderCell('Aksi', flex: 2),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logoMts.png',
            height: 70,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.school, size: 70, color: Colors.grey);
            },
          ),
          const SizedBox(height: 6),
          const Text(
            "MTS Sunan Gunung Jati",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _TableHeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isName;

  const _TableCell(this.text, {required this.flex, this.isName = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          text,
          textAlign: isName ? TextAlign.left : TextAlign.center,
        ),
      ),
    );
  }
}
