import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editSiswa.dart'; // Pastikan path ini benar

/// =======================
/// MODEL DATA (DIPERBARUI)
/// =======================

// Model ini sekarang hanya fokus pada data dari tabel 'absensi'
class Absensi {
  final String status; // 'Hadir', 'Sakit', 'Izin', 'Alfa'
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
  final String statusSiswa; // status_siswa (aktif / nonaktif)
  final Absensi absensiHariIni;
  final String? suratUrlHariIni; // URL surat sekarang disimpan di sini

  Siswa({
    required this.id,
    required this.no,
    required this.nama,
    required this.statusSiswa,
    required this.absensiHariIni,
    this.suratUrlHariIni,
  });

  // Factory ini diperbarui untuk memproses relasi 'absensi' dan 'surat'
  factory Siswa.fromJson(Map<String, dynamic> json) {
    final absensiList = json['absensi'] as List<dynamic>? ?? [];
    final suratList =
        json['surat'] as List<dynamic>? ?? []; // Ambil data dari relasi 'surat'
    final today = DateTime.now().toIso8601String().split('T').first;

    // Cari absensi hari ini dari relasi 'absensi'
    final absensiTodayMap = absensiList
        .cast<Map<String, dynamic>?>()
        .firstWhere((a) => a?['tanggal'] == today, orElse: () => null);

    // Cari surat hari ini dari relasi 'surat'
    final suratTodayMap = suratList.cast<Map<String, dynamic>?>().firstWhere(
      (s) => s?['tanggal'] == today,
      orElse: () => null,
    );

    // Tentukan status absensi. Default-nya 'Alfa' jika tidak ada data.
    final absensi = Absensi(
      status: absensiTodayMap?['keterangan'] ?? 'Alfa',
      tanggal: absensiTodayMap?['tanggal'],
    );

    // Ambil URL surat jika ada
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

  /// ✅ Ambil semua siswa, absensi, dan surat via nested join
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
        throw Exception("Kelas '${widget.namaKelas}' tidak ditemukan di database.");
      }

      final kelasId = kelasResponse['id'];

      // PERBAIKAN: Ambil data dari relasi 'absensi' dan 'surat'
      final data = await _supabase
          .from('siswa')
          .select(
            'id, no, nama, status, absensi(keterangan, tanggal), surat(file_url, tanggal)',
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
          keterangan: siswa.absensiHariIni.status,
          // TAMBAHKAN BARIS INI untuk mengirim URL surat
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
                const Text("😢 Gagal Memuat Data",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _TableCell(siswa.no.toString(), flex: 1),
          _TableCell(siswa.nama, flex: 3, isName: true),
          _TableCell(siswa.absensiHariIni.status, flex: 3),
          Expanded(
            flex: 2,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                onPressed: () => _navigateToEdit(siswa),
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
          const Text("MTS Sunan Gunung Jati",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

/// =======================
/// KOMPONEN TAMBAHAN
/// =======================

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
