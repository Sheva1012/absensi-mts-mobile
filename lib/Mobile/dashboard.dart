import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'KelasScreen.dart'; // Pastikan file ini benar
import 'formLogin.dart';

final _supabase = Supabase.instance.client;

// ====================== MODELS ==========================

class TeacherProfile {
  final String nama;
  final String? avatarUrl;
  final Map<String, List<String>> kelasDiampu;

  TeacherProfile({
    required this.nama,
    required this.kelasDiampu,
    this.avatarUrl,
  });

  factory TeacherProfile.fromSupabase(Map<String, dynamic> data) {
    final kelasData = data['kelas_diampu'];
    final Map<String, List<String>> kelasDiampuTyped = {};

    if (kelasData is Map<String, dynamic>) {
      kelasData.forEach((key, value) {
        if (value is List) {
          kelasDiampuTyped[key] = value.map((item) => item.toString()).toList();
        }
      });
    }

    return TeacherProfile(
      nama: data['nama'] ?? 'Nama Guru',
      avatarUrl: data['avatar_url'],
      kelasDiampu: kelasDiampuTyped,
    );
  }
}

class ClassSummary {
  final String namaKelas;
  final int totalSiswa;
  final int sudahAbsen;
  final int belumAbsen;
  final int tidakMasuk;
  final int terlambat;

  ClassSummary({
    required this.namaKelas,
    required this.totalSiswa,
    required this.sudahAbsen,
    required this.belumAbsen,
    required this.tidakMasuk,
    required this.terlambat,
  });
}

class DashboardData {
  final List<ClassSummary> summaries;
  final int totalSiswaAlfa;

  DashboardData({required this.summaries, required this.totalSiswaAlfa});

  double get persentaseKehadiran {
    final totalSiswa = summaries.fold(0, (sum, item) => sum + item.totalSiswa);
    final totalHadir = summaries.fold(
      0,
      (sum, item) => sum + item.sudahAbsen + item.terlambat,
    );
    if (totalSiswa == 0) return 0.0;
    return (totalHadir / totalSiswa) * 100;
  }
}

// ====================== DASHBOARD SCREEN (CONTROLLER UTAMA) ==========================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<TeacherProfile?> _teacherProfileFuture;

  // STATE UNTUK MENGATUR KONTEN YANG TAMPIL
  String? _selectedKelas; // Jika null, tampilkan Dashboard Home

  @override
  void initState() {
    super.initState();
    _teacherProfileFuture = _fetchTeacherProfile();
  }

  Future<TeacherProfile?> _fetchTeacherProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('guru')
          .select()
          .eq('id', user.id)
          .single();

      return TeacherProfile.fromSupabase(data);
    } catch (e) {
      debugPrint('Error fetching teacher profile: $e');
      return null;
    }
  }

  // Fungsi untuk ganti tampilan ke Dashboard Utama
  void _showDashboard() {
    setState(() {
      _selectedKelas = null;
    });
    // Jika di mobile (drawer terbuka), opsional: Navigator.pop(context);
    // Tapi user minta "jangan otomatis tutup", jadi kita biarkan drawer.
  }

  // Fungsi untuk ganti tampilan ke Kelas Tertentu
  void _showKelas(String namaKelas) {
    setState(() {
      _selectedKelas = namaKelas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeacherProfile?>(
      future: _teacherProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Gagal memuat data profil."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async => await _supabase.auth.signOut(),
                    child: const Text("Kembali ke Login"),
                  ),
                ],
              ),
            ),
          );
        }

        final teacherProfile = snapshot.data!;
        final isDesktop = MediaQuery.of(context).size.width > 800;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Text(
                    _selectedKelas ?? 'Dashboard',
                  ), // Judul berubah dinamis
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
          // Sidebar dikirim callback _showKelas dan _showDashboard
          drawer: isDesktop
              ? null
              : AppSidebar(
                  teacherProfile: teacherProfile,
                  onDashboardTap: _showDashboard,
                  onKelasTap: _showKelas,
                  selectedKelas: _selectedKelas,
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  teacherProfile: teacherProfile,
                  onDashboardTap: _showDashboard,
                  onKelasTap: _showKelas,
                  selectedKelas: _selectedKelas,
                ),

              // AREA KONTEN YANG BERUBAH-UBAH
              Expanded(
                child: _selectedKelas == null
                    ? MainDashboardContent(teacherProfile: teacherProfile)
                    : KelasScreen(
                        namaKelas: _selectedKelas!,
                      ), // KelasScreen ditampilkan di sini
              ),
            ],
          ),
        );
      },
    );
  }
}

// ====================== UTILS ==========================

String normalizeClassName(String name) {
  return name
      .replaceAll(RegExp(r'kelas', caseSensitive: false), '')
      .trim()
      .toUpperCase()
      .replaceAll(' ', '');
}

// ====================== MAIN DASHBOARD CONTENT ==========================

class MainDashboardContent extends StatefulWidget {
  final TeacherProfile teacherProfile;

  const MainDashboardContent({super.key, required this.teacherProfile});

  @override
  State<MainDashboardContent> createState() => _MainDashboardContentState();
}

class _MainDashboardContentState extends State<MainDashboardContent> {
  late Future<DashboardData> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _dashboardDataFuture = _fetchDashboardData();
    });
  }

  Future<DashboardData> _fetchDashboardData() async {
    try {
      final rawClassNames = widget.teacherProfile.kelasDiampu.values
          .expand((list) => list)
          .toList();

      final List<String> normalizedClassNames = rawClassNames
          .map((e) => normalizeClassName(e))
          .toList();

      final kelasRaw = await _supabase.from('kelas').select('id, nama_kelas');

      final kelasDataList = kelasRaw.where((kelas) {
        final namaDb = kelas['nama_kelas'];
        if (namaDb == null) return false;
        return normalizedClassNames.contains(normalizeClassName(namaDb));
      }).toList();

      if (kelasDataList.isEmpty) {
        return DashboardData(summaries: [], totalSiswaAlfa: 0);
      }

      final kelasIdList = kelasDataList
          .map<int?>((e) => e['id'])
          .whereType<int>()
          .toList();

      final siswaList = await _supabase
          .from('siswa')
          .select('id, kelas_id')
          .inFilter('kelas_id', kelasIdList);

      final allSiswaIds = siswaList
          .map<int?>((s) => s['id'])
          .whereType<int>()
          .toList();

      final now = DateTime.now();
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final todayEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      final absensiRaw = allSiswaIds.isEmpty
          ? []
          : await _supabase
                .from('absensi')
                .select('siswa_id, status, created_at')
                .inFilter('siswa_id', allSiswaIds)
                .gte('created_at', todayStart)
                .lte('created_at', todayEnd);

      final todayAbsensiList = absensiRaw.where((a) {
        final date = DateTime.tryParse(a['created_at'] ?? '');
        if (date == null) return false;
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();

      final summaries = kelasDataList
          .map((kelas) {
            final kelasId = kelas['id'];
            final namaKelas = kelas['nama_kelas'] ?? "-";

            final siswaDalamKelas = siswaList
                .where((s) => s['kelas_id'] == kelasId)
                .map<int?>((s) => s['id'])
                .whereType<int>()
                .toSet();

            final totalSiswa = siswaDalamKelas.length;

            final absensiKelas = todayAbsensiList.where((a) {
              return siswaDalamKelas.contains(a['siswa_id']);
            }).toList();

            // 1. Hitung Hadir
            final hadir = absensiKelas
                .where((a) => a['status'].toString().toLowerCase() == 'hadir')
                .length;

            // 2. Hitung Terlambat
            final terlambat = absensiKelas
                .where(
                  (a) => a['status'].toString().toLowerCase() == 'terlambat',
                )
                .length;

            // 3. Hitung Tidak Masuk (Hanya Sakit & Izin)
            // 'Alfa' kita pindahkan ke kategori 'Belum Absen' karena itu default sistem
            final tidakMasuk = absensiKelas.where((a) {
              final st = a['status'].toString().toLowerCase();
              return st == 'sakit' || st == 'izin';
            }).length;

            // 4. Hitung Belum Absen (LOGIKA BARU)
            // Belum Absen = (Siswa yg belum punya row data sama sekali) + (Siswa dengan status 'alfa')
            final rowCount = absensiKelas.length;
            final dataMissing =
                totalSiswa - rowCount; // Siswa baru yg belum kena cron

            final statusAlfa = absensiKelas
                .where((a) => a['status'].toString().toLowerCase() == 'alfa')
                .length;

            final belumAbsen = dataMissing + statusAlfa;

            return ClassSummary(
              namaKelas: namaKelas,
              totalSiswa: totalSiswa,
              sudahAbsen: hadir,
              terlambat: terlambat,
              belumAbsen: belumAbsen, // Alfa masuk sini
              tidakMasuk: tidakMasuk, // Hanya Sakit/Izin
            );
          })
          .whereType<ClassSummary>()
          .toList();

      // Total Alfa untuk data global (jika diperlukan)
      final totalAlfa = todayAbsensiList
          .where((a) => a['status'].toString().toLowerCase() == 'alfa')
          .length;

      return DashboardData(summaries: summaries, totalSiswaAlfa: totalAlfa);
    } catch (e, s) {
      debugPrint("Dashboard Error: $e");
      debugPrint(s.toString());
      return DashboardData(summaries: [], totalSiswaAlfa: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";

    return FutureBuilder<DashboardData>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ringkasan Hari Ini",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildQuickStatsCard(data.persentaseKehadiran),
              const SizedBox(height: 24),
              Text(
                "Summary Kelas",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              if (data.summaries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Tidak ada kelas yang diajar."),
                  ),
                ),
              ...data.summaries.map(_buildClassSummaryCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsCard(double percentage) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.teal,
                    ),
                  ),
                  Center(
                    child: Text(
                      "${percentage.toStringAsFixed(0)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tingkat Kehadiran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text("Persentase siswa yang hadir/terlambat hari ini."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSummaryCard(ClassSummary summary) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summary.namaKelas,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text("Total: ${summary.totalSiswa}"),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat("Hadir", summary.sudahAbsen, Colors.green),
                _stat("Terlambat", summary.terlambat, Colors.purple),
                _stat("Tidak Masuk", summary.tidakMasuk, Colors.red),
                _stat("Belum Absen", summary.belumAbsen, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }
}

// ====================== SIDEBAR (MODIFIED) ==========================

class AppSidebar extends StatefulWidget {
  final TeacherProfile teacherProfile;
  final Function(String) onKelasTap; // Callback saat kelas diklik
  final VoidCallback onDashboardTap; // Callback saat dashboard diklik
  final String? selectedKelas; // Untuk highlight menu aktif

  const AppSidebar({
    super.key,
    required this.teacherProfile,
    required this.onKelasTap,
    required this.onDashboardTap,
    this.selectedKelas,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int _expandedIndex = -1; // Untuk melacak accordion mana yang terbuka

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tingkatKelas = widget.teacherProfile.kelasDiampu.keys
        .toList();
    tingkatKelas.sort();

    // Menentukan apakah dashboard sedang aktif
    bool isDashboardActive = widget.selectedKelas == null;

    return Container(
      width: 250,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header Sidebar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MTs Sunan Gunung Jati',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Tombol tutup sidebar manual (Opsional untuk mobile)
                  if (!MediaQuery.of(context).size.width.isInfinite &&
                      MediaQuery.of(context).size.width < 800)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    isSelected: isDashboardActive,
                    onTap: () {
                      widget.onDashboardTap();

                      Future.delayed(const Duration(milliseconds: 80), () {
                        if (Navigator.canPop(context))
                          Navigator.of(context).pop();
                      });
                    },
                  ),

                  // List Tingkat Kelas
                  ...List.generate(tingkatKelas.length, (index) {
                    final namaTingkat = tingkatKelas[index];
                    final subMenus =
                        widget.teacherProfile.kelasDiampu[namaTingkat]!;

                    return _buildClassExpansionTile(
                      title: namaTingkat,
                      index: index,
                      subMenus: subMenus,
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),

            // Footer Profile
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.teacherProfile.avatarUrl != null
                        ? NetworkImage(widget.teacherProfile.avatarUrl!)
                        : null,
                    child: widget.teacherProfile.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.teacherProfile.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: 'Logout',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildClassExpansionTile({
    required String title,
    required int index,
    required List<String> subMenus,
  }) {
    // Cek apakah salah satu submenu (kelas) di dalam grup ini sedang dipilih
    bool isGroupContainsSelected = subMenus.contains(widget.selectedKelas);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isGroupContainsSelected || _expandedIndex == index,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedIndex = expanded ? index : -1;
          });
        },
        leading: Icon(
          Icons.class_outlined,
          color: isGroupContainsSelected ? Colors.blue[800] : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isGroupContainsSelected
                ? FontWeight.bold
                : FontWeight.normal,
            color: isGroupContainsSelected ? Colors.blue[800] : Colors.black,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16),
        children: subMenus.map((namaKelas) {
          return _buildSubMenuItem(
            title: namaKelas,
            isSelected: widget.selectedKelas == namaKelas,
            onTap: () {
              widget.onKelasTap(namaKelas);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Scaffold.of(context).isDrawerOpen) {
                  Scaffold.of(context).closeDrawer();
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
