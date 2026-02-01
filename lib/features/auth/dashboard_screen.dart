import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/models.dart';
import 'dashboard_logic.dart';
import 'form_login.dart';
import '../kelas/kelas_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardLogic()..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  String? _selectedKelas;

  void _onKelasSelected(String namaKelas) {
    setState(() => _selectedKelas = namaKelas);
    Navigator.pop(context); // Close drawer
  }

  void _onHomeSelected() {
    setState(() => _selectedKelas = null);
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<DashboardLogic>();

    if (logic.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (logic.errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(logic.errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: logic.loadDashboard,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_selectedKelas ?? 'Dashboard Guru'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: _buildDrawer(context, logic),
      body: _selectedKelas != null
          ? PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (didPop) return;
                setState(() => _selectedKelas = null);
              },
              child: KelasScreen(namaKelas: _selectedKelas!),
            )
          : RefreshIndicator(
              onRefresh: logic.loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderDate(),
                  const SizedBox(height: 16),
                  _AttendanceCard(rate: logic.attendanceRate),
                  const SizedBox(height: 24),
                  Text(
                    'Ringkasan Kelas Hari Ini',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (logic.summaryList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Belum ada kelas yang diajar.'),
                      ),
                    ),
                  ...logic.summaryList
                      .map((data) => _ClassSummaryCard(data: data)),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context, DashboardLogic logic) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: UiConstants.primaryColor),
            accountName: Text(
              logic.guruProfile?.nama ?? 'Guru',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(AppConstants.schoolName),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: logic.guruProfile?.displayAvatarUrl != null
                  ? NetworkImage(logic.guruProfile!.displayAvatarUrl!)
                  : null,
              child: logic.guruProfile?.displayAvatarUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: _onHomeSelected,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Daftar Kelas',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: logic.kelasDiampu.entries.map((entry) {
                return ExpansionTile(
                  leading: const Icon(Icons.class_),
                  title: Text(entry.key), // Tingkat name (e.g. "Kelas 7")
                  children: entry.value.map((kelasName) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 50),
                      title: Text(kelasName),
                      onTap: () => _onKelasSelected(kelasName),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await logic.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDate() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final double rate;

  const _AttendanceCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 8,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  backgroundColor: Colors.white24,
                ),
                Center(
                  child: Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Kehadiran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Akumulasi kehadiran siswa hari ini',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassSummaryCard extends StatelessWidget {
  final ClassSummary data;

  const _ClassSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.namaKelas,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${data.totalSiswa}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem('Hadir', data.hadir, Colors.green),
                _StatItem('Telat', data.terlambat, Colors.orange),
                _StatItem('Sakit', data.sakit, Colors.blue),
                _StatItem('Izin', data.izin, Colors.purple),
                _StatItem('Alfa', data.alfa, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
