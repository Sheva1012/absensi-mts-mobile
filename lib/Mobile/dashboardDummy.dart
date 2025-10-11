import 'package:flutter/material.dart';
// Hapus import yang berhubungan dengan Supabase dan halaman lain untuk versi dummy ini
// import 'package:app_absensi_mts/KelasScreen.dart';
// import 'package:app_absensi_mts/login_screen.dart';

// --- DATA DUMMY ---
// Kita buat data palsu di sini untuk ditampilkan di UI

final dummyTeacherProfile = TeacherProfile(
  nama: 'Budi Santoso',
  avatarUrl: null, // Biarkan null untuk menampilkan avatar default
  kelasDiampu: {
    'Kelas 7': ['Kelas 7A', 'Kelas 7B'],
    'Kelas 8': ['Kelas 8A', 'Kelas 8B', 'Kelas 8C'],
    'Kelas 9': ['Kelas 9A'],
  },
);

final dummyDashboardData = DashboardData(
  summaries: [
    ClassSummary(
        namaKelas: 'Kelas 8A',
        totalSiswa: 30,
        sudahAbsen: 25,
        belumAbsen: 5,
        butuhValidasi: 1),
    ClassSummary(
        namaKelas: 'Kelas 8B',
        totalSiswa: 32,
        sudahAbsen: 30,
        belumAbsen: 2,
        butuhValidasi: 0),
    ClassSummary(
        namaKelas: 'Kelas 8C',
        totalSiswa: 28,
        sudahAbsen: 28,
        belumAbsen: 0,
        butuhValidasi: 2),
  ],
  totalSiswaAlfa: 3,
  totalButuhValidasi: 3,
);

// --- MODEL DATA (Sama seperti di file dinamis) ---

class TeacherProfile {
  final String nama;
  final String? avatarUrl;
  final Map<String, List<String>> kelasDiampu;

  TeacherProfile({
    required this.nama,
    required this.kelasDiampu,
    this.avatarUrl,
  });
}

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

class DashboardData {
  final List<ClassSummary> summaries;
  final int totalSiswaAlfa;
  final int totalButuhValidasi;

  DashboardData({
    required this.summaries,
    required this.totalSiswaAlfa,
    required this.totalButuhValidasi,
  });

  double get persentaseKehadiran {
    final totalSiswa = summaries.fold(0, (sum, item) => sum + item.totalSiswa);
    final totalHadir = summaries.fold(0, (sum, item) => sum + item.sudahAbsen);
    if (totalSiswa == 0) return 0.0;
    return (totalHadir / totalSiswa) * 100;
  }
}

// --- WIDGET UTAMA (Versi Dummy) ---

class DashboardDummyScreen extends StatelessWidget {
  const DashboardDummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Dashboard (Dummy)'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
      drawer: isDesktop ? null : AppSidebar(teacherProfile: dummyTeacherProfile),
      body: Row(
        children: [
          if (isDesktop) AppSidebar(teacherProfile: dummyTeacherProfile),
          const Expanded(child: MainDashboardContent()),
        ],
      ),
    );
  }
}

// --- KONTEN UTAMA DASHBOARD (Versi Dummy) ---

class MainDashboardContent extends StatelessWidget {
  const MainDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Langsung gunakan data dummy, tidak perlu FutureBuilder
    final data = dummyDashboardData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Ringkasan Hari Ini",
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildQuickStatsCard(data.persentaseKehadiran),
        const SizedBox(height: 24),
        // PERBAIKAN: Kirim 'context' ke helper method
        _buildUrgentNotifications(context, data.totalSiswaAlfa, data.totalButuhValidasi),
        const SizedBox(height: 24),
        Text("Summary Kelas", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (data.summaries.isEmpty)
          const Center(child: Text("Tidak ada kelas yang diajar.")),
        ...data.summaries.map((summary) => _buildClassSummaryCard(summary)),
      ],
    );
  }

  // Helper-helper widget untuk UI disalin dari file dinamis
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                  Center(
                      child: Text("${percentage.toStringAsFixed(0)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tingkat Kehadiran",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                      "Persentase siswa yang hadir hari ini dari semua kelas."),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // PERBAIKAN: Terima 'BuildContext' sebagai parameter
  Widget _buildUrgentNotifications(BuildContext context, int totalAlfa, int totalValidasi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Notifikasi Penting",
            style:
                Theme.of(context).textTheme.titleMedium),
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
              leading:
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              title: Text("$totalAlfa Siswa Alfa"),
              subtitle: Text(
                  "Segera tindak lanjuti siswa yang tidak hadir tanpa keterangan."),
            ),
          ),
        if (totalValidasi > 0)
          Card(
            color: Colors.orange[50],
            child: ListTile(
              leading: Icon(Icons.pending_actions_outlined,
                  color: Colors.orange[700]),
              title: Text("$totalValidasi Surat Pending"),
              subtitle: Text(
                  "Terdapat surat keterangan sakit/izin yang perlu divalidasi."),
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
            Text(summary.namaKelas,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text("Total Siswa: ${summary.totalSiswa}",
                style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Hadir", summary.sudahAbsen, Colors.green),
                _buildStatItem("Belum Hadir", summary.belumAbsen, Colors.orange),
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
        Text(count.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, color: color)),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

// --- SIDEBAR (Versi Dummy) ---

class AppSidebar extends StatefulWidget {
  final TeacherProfile teacherProfile;
  const AppSidebar({super.key, required this.teacherProfile});
  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int _selectedIndex = 0;

  void _handleLogout() {
    // Di versi dummy, kita bisa tampilkan pesan saja
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logout disimulasikan.")),
    );
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
                    child: Text('MTs Sunan Gunung Jati',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
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
                    final subMenus =
                        widget.teacherProfile.kelasDiampu[namaTingkat]!;
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app,
                        color: Colors.redAccent),
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

  // Helper-helper widget untuk UI Sidebar
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
        leading:
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
        title: Text(title,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
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
        title: Text(title,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 14)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildClassExpansionTile({
    required String title,
    required int baseIndex,
    required List<String> subMenus,
  }) {
    bool isGroupSelected = _selectedIndex >= baseIndex &&
        _selectedIndex < baseIndex + subMenus.length + 1;
    return ExpansionTile(
      leading: const Icon(Icons.people_outline),
      title: Text(title,
          style: TextStyle(
              fontWeight: isGroupSelected ? FontWeight.bold : FontWeight.normal)),
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
            // Aksi navigasi bisa dikomentari atau diganti dengan SnackBar di versi dummy
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Navigasi ke ${subMenus[index]}")),
            );
            setState(() => _selectedIndex = currentIndex);
          },
        );
      }),
    );
  }
}

