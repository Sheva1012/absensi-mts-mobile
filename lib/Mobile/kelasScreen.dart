import 'dart:async'; // Import untuk menggunakan Timer (debounce)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absensi_mts/Mobile/editSiswa.dart';

// --- Model Class Siswa ---
class Siswa {
  final int id;
  final int no;
  final String nama;
  final String status;
  final String? keterangan;

  Siswa({
    required this.id,
    required this.no,
    required this.nama,
    required this.status,
    this.keterangan,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      id: json['id'] ?? 0,
      no: json['no'] ?? 0,
      nama: json['nama'] ?? 'Tanpa Nama',
      status: json['status'] ?? 'Tidak Diketahui',
      keterangan: json['keterangan'],
    );
  }
}

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

  // Buat daftar terpisah untuk data asli dari database
  List<Siswa> _originalSiswaList = [];
  // Daftar ini yang akan ditampilkan di UI dan difilter
  List<Siswa> _filteredSiswaList = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Panggil _fetchData saat pertama kali layar dibuka
    _fetchData();
    // Tambahkan listener untuk mendeteksi perubahan pada input pencarian
    _searchController.addListener(_filterSiswa);
  }

  @override
  void dispose() {
    // Hapus listener dan dispose controller untuk menghindari memory leak
    _searchController.removeListener(_filterSiswa);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// PERBAIKAN: Fungsi baru untuk memfilter daftar siswa yang sudah ada di memori
  void _filterSiswa() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSiswaList = _originalSiswaList;
      } else {
        _filteredSiswaList = _originalSiswaList.where((siswa) {
          return siswa.nama.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Mengambil data dari database
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // LANGKAH 1: Cari ID kelas berdasarkan nama_kelas
      final kelasResponse = await _supabase
          .from('kelas')
          .select('id')
          .eq('nama_kelas', widget.namaKelas)
          .maybeSingle();

      if (kelasResponse == null || kelasResponse['id'] == null) {
        throw Exception(
            "Kelas dengan nama '${widget.namaKelas}' tidak ditemukan di database.");
      }

      final kelasId = kelasResponse['id'];

      // LANGKAH 2: Ambil semua data siswa untuk kelas ini
      final data = await _supabase
          .from('siswa')
          .select()
          .eq('kelas_id', kelasId)
          .order('no', ascending: true);

      if (!mounted) return;

      setState(() {
        // Simpan data asli dan salin ke daftar yang akan difilter
        _originalSiswaList = data.map((item) => Siswa.fromJson(item)).toList();
        _filteredSiswaList = _originalSiswaList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
          keterangan: siswa.keterangan,
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
                backgroundColor: Colors.green),
          );
      }
    });
  }

  // --- UI (Build Method dan semua Helper Widget di bawah ini TIDAK BERUBAH) ---
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
          child: Center(child: CircularProgressIndicator()));
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
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleRefresh,
                  child: const Text('Coba Lagi'),
                )
              ],
            ),
          ),
        ),
      );
    }
    // PERBAIKAN: Gunakan _filteredSiswaList
    if (_filteredSiswaList.isEmpty) {
      return SliverFillRemaining(
          child: Center(
              child: Text(_searchController.text.isEmpty
                  ? "Tidak ada data siswa di kelas ini."
                  : "Siswa dengan nama '${_searchController.text}' tidak ditemukan.")));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        // PERBAIKAN: Gunakan _filteredSiswaList
        itemCount: _filteredSiswaList.length,
        itemBuilder: (context, index) => _buildTableRow(_filteredSiswaList[index]),
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
          _TableCell(siswa.status, flex: 3),
          Expanded(
            flex: 2,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
    // Widget pencarian sekarang hanya TextField
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama siswa...',
        prefixIcon: const Icon(Icons.search),
        // Tambahkan tombol 'clear' untuk menghapus teks
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
          Image.asset('assets/logoMts.png',
              height: 70, errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.school, size: 70, color: Colors.grey);
          }),
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
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isName; // Tambahan untuk meratakan teks nama ke kiri
  const _TableCell(this.text, {required this.flex, this.isName = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(text, textAlign: isName ? TextAlign.left : TextAlign.center),
      ),
    );
  }
}

