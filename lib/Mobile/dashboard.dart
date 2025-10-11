import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'KelasScreen.dart'; // Pastikan path ini benar
import 'formLogin.dart'; // Pastikan path ini benar

final _supabase = Supabase.instance.client;

// Model untuk profil guru (tidak berubah)
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

// Model untuk menyimpan data summary per kelas
class ClassSummary {
  final String namaKelas;
  final int totalSiswa;
  final int sudahAbsen;
  final int belumAbsen;
  final int butuhValidasi;

  ClassSummary({
    required this.namaKelas,
    required this.totalSiswa,
    required this.sudahAbsen,
    required this.belumAbsen,
    required this.butuhValidasi,
  });
}

// Model untuk menyimpan data dashboard secara keseluruhan
class DashboardData {
  final List<ClassSummary> summaries;
  final int totalSiswaAlfa;
  final int totalButuhValidasi;

  DashboardData({
    required this.summaries,
    required this.totalSiswaAlfa,
    required this.totalButuhValidasi,
  });

  // Kalkulasi statistik cepat
  double get persentaseKehadiran {
    final totalSiswa = summaries.fold(0, (sum, item) => sum + item.totalSiswa);
    final totalHadir = summaries.fold(0, (sum, item) => sum + item.sudahAbsen);
    if (totalSiswa == 0) return 0.0;
    return (totalHadir / totalSiswa) * 100;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<TeacherProfile?> _teacherProfileFuture;

  @override
  void initState() {
    super.initState();
    _teacherProfileFuture = _fetchTeacherProfile();
  }

  Future<TeacherProfile?> _fetchTeacherProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data =
          await _supabase.from('guru').select().eq('id', user.id).single();
      return TeacherProfile.fromSupabase(data);
    } catch (e) {
      print('Error fetching teacher profile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeacherProfile?>(
      future: _teacherProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal memuat data profil.'),
                  ElevatedButton(
                    onPressed: () async => await _supabase.auth.signOut(),
                    child: const Text('Kembali ke Login'),
                  )
                ],
              ),
            ),
          );
        }

        final teacherProfile = snapshot.data!;
        final isDesktop = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Dashboard'),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
          drawer: isDesktop ? null : AppSidebar(teacherProfile: teacherProfile),
          body: Row(
            children: [
              if (isDesktop) AppSidebar(teacherProfile: teacherProfile),
              // Ganti MainContent statis dengan yang dinamis
              Expanded(
                  child: MainDashboardContent(teacherProfile: teacherProfile)),
            ],
          ),
        );
      },
    );
  }
}

// KONTEN UTAMA DASHBOARD YANG BARU DAN DINAMIS
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

  // PERBAIKAN: Fungsi ini telah ditulis ulang untuk mengambil data dari tabel 'absensi' dan 'surat'
  Future<DashboardData> _fetchDashboardData() async {
    try {
      final List<String> namaKelasList = widget.teacherProfile.kelasDiampu.values
          .expand((list) => list)
          .toList();

      if (namaKelasList.isEmpty) {
        return DashboardData(summaries: [], totalSiswaAlfa: 0, totalButuhValidasi: 0);
      }

      final List<Map<String, dynamic>> kelasDataList = await _supabase
          .from('kelas')
          .select('id, nama_kelas')
          .inFilter('nama_kelas', namaKelasList);

      final List<int> kelasIdList = kelasDataList.map<int>((e) => e['id'] as int).toList();
      if (kelasIdList.isEmpty) {
        return DashboardData(summaries: [], totalSiswaAlfa: 0, totalButuhValidasi: 0);
      }
      
      final List<Map<String, dynamic>> allSiswaList = await _supabase
        .from('siswa')
        .select('id, kelas_id')
        .inFilter('kelas_id', kelasIdList);
        
      final List<int> allSiswaIds = allSiswaList.map<int>((s) => s['id'] as int).toList();
      if (allSiswaIds.isEmpty) {
        return DashboardData(summaries: [], totalSiswaAlfa: 0, totalButuhValidasi: 0);
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
      final tomorrowStart = DateTime(today.year, today.month, today.day + 1).toIso8601String();
      
      // Ambil data dari tabel 'absensi'
      final List<Map<String, dynamic>> allAbsensiList = await _supabase
        .from('absensi')
        .select('siswa_id, keterangan')
        .inFilter('siswa_id', allSiswaIds)
        .gte('created_at', todayStart)
        .lt('created_at', tomorrowStart);

      // Ambil data dari tabel 'surat'
      final List<Map<String, dynamic>> allSuratList = await _supabase
        .from('surat') // <-- Mengambil dari tabel 'surat'
        .select('siswa_id, file_url')
        .inFilter('siswa_id', allSiswaIds)
        .gte('created_at', todayStart)
        .lt('created_at', tomorrowStart);

      final summaries = kelasDataList.map((kelasData) {
        final kelasId = kelasData['id'];
        final namaKelas = kelasData['nama_kelas'];

        final siswaIdsInThisClass = allSiswaList
            .where((s) => s['kelas_id'] == kelasId)
            .map<int>((s) => s['id'] as int)
            .toSet();
        
        final totalSiswa = siswaIdsInThisClass.length;

        final absensiForThisClass = allAbsensiList
            .where((a) => siswaIdsInThisClass.contains(a['siswa_id']))
            .toList();

        final suratForThisClass = allSuratList
            .where((s) => siswaIdsInThisClass.contains(s['siswa_id']))
            .toList();

        final sudahAbsen = absensiForThisClass.where((a) => a['keterangan'] == 'Hadir').length;
        final belumAbsen = totalSiswa - absensiForThisClass.length;
        final butuhValidasi = suratForThisClass.length; // Hitung dari tabel 'surat'

        return ClassSummary(
            namaKelas: namaKelas,
            totalSiswa: totalSiswa,
            sudahAbsen: sudahAbsen,
            belumAbsen: belumAbsen,
            butuhValidasi: butuhValidasi,
        );
      }).toList();

      final totalSiswaAlfa = allAbsensiList.where((a) => a['keterangan'] == 'Alfa').length;
      final totalButuhValidasi = allSuratList.length;

      return DashboardData(
        summaries: summaries,
        totalSiswaAlfa: totalSiswaAlfa,
        totalButuhValidasi: totalButuhValidasi,
      );
    } catch (e) {
      print("Error fetching dashboard data: $e");
      throw Exception("Gagal memuat data dashboard.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Error: ${snapshot.error}"),
                ElevatedButton(onPressed: _refreshData, child: const Text("Coba Lagi")),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Ringkasan Hari Ini", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              _buildQuickStatsCard(data.persentaseKehadiran),
              const SizedBox(height: 24),
              
              _buildUrgentNotifications(data.totalSiswaAlfa, data.totalButuhValidasi),
              const SizedBox(height: 24),
              
              Text("Summary Kelas", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              if (data.summaries.isEmpty)
                const Center(child: Text("Tidak ada kelas yang diajar.")),
              ...data.summaries.map((summary) => _buildClassSummaryCard(summary)),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                  Center(child: Text("${percentage.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tingkat Kehadiran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Persentase siswa yang hadir hari ini dari semua kelas."),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentNotifications(int totalAlfa, int totalValidasi) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text("Notifikasi Penting", style: Theme.of(context).textTheme.titleMedium),
         const SizedBox(height: 8),
         if (totalAlfa == 0 && totalValidasi == 0)
           const Card(
             color: Colors.white,
             child: ListTile(
               leading: Icon(Icons.check_circle_outline, color: Colors.green),
               title: Text("Tidak ada notifikasi"),
               subtitle: Text("Semua absensi sudah lengkap."),
             ),
           ),
         if (totalAlfa > 0)
           Card(
             color: Colors.red[50],
             child: ListTile(
               leading: Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
               title: Text("$totalAlfa Siswa Alfa"),
               subtitle: Text("Segera tindak lanjuti siswa yang tidak hadir tanpa keterangan."),
             ),
           ),
         if (totalValidasi > 0)
           Card(
             color: Colors.orange[50],
             child: ListTile(
               leading: Icon(Icons.pending_actions_outlined, color: Colors.orange[700]),
               title: Text("$totalValidasi Surat Pending"),
               subtitle: Text("Terdapat surat keterangan sakit/izin yang perlu divalidasi."),
             ),
           ),
       ],
     );
  }

  Widget _buildClassSummaryCard(ClassSummary summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.namaKelas, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text("Total Siswa: ${summary.totalSiswa}", style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Hadir", summary.sudahAbsen, Colors.green),
                _buildStatItem("Belum Absen", summary.belumAbsen, Colors.orange),
                _buildStatItem("Validasi", summary.butuhValidasi, Colors.blue),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}


// SIDEBAR (Tidak ada perubahan signifikan, hanya memastikan ada)
class AppSidebar extends StatefulWidget {
  final TeacherProfile teacherProfile;
  const AppSidebar({super.key, required this.teacherProfile});
  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int _selectedIndex = 0;
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
    final List<String> tingkatKelas =
        widget.teacherProfile.kelasDiampu.keys.toList();
    tingkatKelas.sort();
    return Container(
      width: 250,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('MTs Sunan Gunung Jati', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      if (Scaffold.of(context).hasDrawer) {
                        Scaffold.of(context).closeDrawer();
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    index: 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  ...List.generate(tingkatKelas.length, (index) {
                    final namaTingkat = tingkatKelas[index];
                    final subMenus = widget.teacherProfile.kelasDiampu[namaTingkat]!;
                    return _buildClassExpansionTile(
                      title: namaTingkat,
                      baseIndex: (index + 1) * 10,
                      subMenus: subMenus,
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                   CircleAvatar(
                      radius: 20,
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
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
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required int index,
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
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 14)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildClassExpansionTile({
    required String title,
    required int baseIndex,
    required List<String> subMenus,
  }) {
    bool isGroupSelected =
        _selectedIndex >= baseIndex && _selectedIndex < baseIndex + subMenus.length + 1;
    return ExpansionTile(
      leading: const Icon(Icons.people_outline),
      title: Text(title, style: TextStyle(fontWeight: isGroupSelected ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: isGroupSelected ? Colors.blue.withOpacity(0.05) : null,
      childrenPadding: const EdgeInsets.only(left: 30),
      onExpansionChanged: (isExpanded) {
        if (isExpanded) {
          setState(() {
            if (!isGroupSelected) _selectedIndex = baseIndex;
          });
        }
      },
      children: List.generate(subMenus.length, (index) {
        int currentIndex = baseIndex + index + 1;
        return _buildSubMenuItem(
          title: subMenus[index],
          index: currentIndex,
          isSelected: _selectedIndex == currentIndex,
          onTap: () {
            setState(() => _selectedIndex = currentIndex);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KelasScreen(namaKelas: subMenus[index])),
            );
          },
        );
      }),
    );
  }
}

