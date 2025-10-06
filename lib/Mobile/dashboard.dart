import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absensi_mts/Mobile/kelasscreen.dart';
import 'package:app_absensi_mts/Mobile/formLogin.dart';

final _supabase = Supabase.instance.client;

class TeacherProfile {
  final String nama;
  final Map<String, List<String>> kelasDiampu;

  TeacherProfile({required this.nama, required this.kelasDiampu});

  // PERBAIKAN: Membuat factory lebih tangguh terhadap data yang salah format
  factory TeacherProfile.fromSupabase(Map<String, dynamic> data) {
    final kelasData = data['kelas_diampu'];
    final Map<String, List<String>> kelasDiampuTyped =
        {};

    // Cek jika data adalah Map sebelum diproses
    if (kelasData is Map<String, dynamic>) {
      kelasData.forEach((key, value) {
        // Untuk setiap entri, cek jika nilainya adalah List
        if (value is List) {
          kelasDiampuTyped[key] = value.map((item) => item.toString()).toList();
        } else {
          // Cetak peringatan jika format data salah, agar mudah di-debug
          print(
            "Peringatan: Data untuk '$key' di 'kelas_diampu' bukan List, melainkan ${value.runtimeType}. Entri ini dilewati.",
          );
        }
      });
    }

    return TeacherProfile(
      nama: data['nama'] ?? 'Nama Guru',
      kelasDiampu:
          kelasDiampuTyped,
    );
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

  /// Fungsi untuk mengambil data profil guru dari Supabase dengan LOGGING
  Future<TeacherProfile?> _fetchTeacherProfile() async {
    // --- LOGGING ---
    print("--- Memulai _fetchTeacherProfile ---");

    final user = _supabase.auth.currentUser;
    if (user == null) {
      print("[DEBUG] Gagal: Pengguna tidak ditemukan (null).");
      return null;
    }

    try {
      // --- LOGGING ---
      print(
        "[DEBUG] Mencoba mengambil data dari tabel 'guru' untuk user ID: ${user.id}",
      );

      final data = await _supabase
          .from('guru') // <-- PASTIKAN NAMA TABEL INI BENAR
          .select()
          .eq('id', user.id) // <-- PASTIKAN NAMA KOLOM ID INI BENAR
          .single();

      // --- LOGGING ---
      print("[DEBUG] Sukses: Data profil berhasil diambil.");
      // print("[DEBUG] Data mentah: $data"); // Uncomment untuk melihat data

      return TeacherProfile.fromSupabase(data);
    } catch (e) {
      // --- LOGGING ---
      print("!!! TERJADI ERROR saat _fetchTeacherProfile !!!");
      print("Tipe Error: ${e.runtimeType}");
      print("Pesan Error: ${e.toString()}");
      print("--- Selesai Error ---");
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Tampilan error ini yang Anda lihat
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal memuat data profil.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _supabase.auth.signOut();
                    },
                    child: const Text('Kembali ke Login'),
                  ),
                ],
              ),
            ),
          );
        }

        final teacherProfile = snapshot.data!;
        final isDesktop = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('MTs Sunan Gunung Jati'),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
          drawer: isDesktop ? null : AppSidebar(teacherProfile: teacherProfile),
          body: Row(
            children: [
              if (isDesktop) AppSidebar(teacherProfile: teacherProfile),
              const Expanded(child: MainContent()),
            ],
          ),
        );
      },
    );
  }
}

// ... (Sisa kode: AppSidebar, MainContent, dll. tidak perlu diubah)
// Salin sisa kode dari file dashboard Anda sebelumnya.
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
    final List<String> tingkatKelas = widget.teacherProfile.kelasDiampu.keys
        .toList();
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
                    child: Text(
                      'MTs Sunan Gunung Jati',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Color(0xFFE0E0E0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teacherProfile.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.redAccent,
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
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
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
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
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
        _selectedIndex >= baseIndex &&
        _selectedIndex < baseIndex + subMenus.length + 1;
    return ExpansionTile(
      leading: const Icon(Icons.people_outline),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isGroupSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isGroupSelected ? Colors.blue.withOpacity(0.1) : null,
      childrenPadding: const EdgeInsets.only(left: 30),
      onExpansionChanged: (isExpanded) {
        if (isExpanded) {
          setState(() {
            if (!isGroupSelected) {
              _selectedIndex = baseIndex;
            }
          });
        }
      },
      children: List.generate(subMenus.length, (index) {
        int currentIndex = baseIndex + index + 1;
        return _buildSubMenuItem(
          title: subMenus[index],
          index: currentIndex,
          isSelected: _selectedIndex == currentIndex,
          // KODE YANG BENAR DI lib/dashboard.dart
          onTap: () {
            setState(() => _selectedIndex = currentIndex);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KelasScreen(
                  // Kirim nama kelas apa adanya, tanpa diubah
                  namaKelas: subMenus[index],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class MainContent extends StatelessWidget {
  const MainContent({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logoMts.png', width: 150),
            const SizedBox(height: 20),
            const Text(
              'DASHBOARD',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Center(
              child: Text(
                'Pilih menu di samping untuk menampilkan data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
