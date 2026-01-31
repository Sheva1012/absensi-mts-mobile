import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'kelas_logic.dart';
import 'editSiswa.dart'; // Pastikan file ini ada

class KelasScreen extends StatelessWidget {
  final String namaKelas;

  const KelasScreen({super.key, required this.namaKelas});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KelasLogic()..init(namaKelas),
      child: const _KelasScreenView(),
    );
  }
}

class _KelasScreenView extends StatelessWidget {
  const _KelasScreenView();

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<KelasLogic>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // App Bar sederhana untuk navigasi kembali
      appBar: AppBar(
        title: Text(logic.currentClassName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- HEADER & SEARCH ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: logic.searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama siswa...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: logic.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => logic.searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                // Header Tabel
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      _HeaderCell('No', flex: 1),
                      _HeaderCell('Nama', flex: 4, alignLeft: true),
                      _HeaderCell('Status', flex: 2),
                      _HeaderCell('Aksi', flex: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- LIST CONTENT ---
          Expanded(
            child: logic.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logic.errorMessage.isNotEmpty
                ? _buildErrorState(context, logic)
                : RefreshIndicator(
                    onRefresh: () async => await logic.fetchData(),
                    child: logic.filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: logic.filteredList.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = logic.filteredList[index];
                              return _SiswaRowItem(
                                key: ValueKey(item['id']),
                                item: item,
                                index: index + 1,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: const Text("Tidak ada data siswa ditemukan."),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, KelasLogic logic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(logic.errorMessage, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => logic.fetchData(),
            child: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }
}

class _SiswaRowItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const _SiswaRowItem({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final logic = context.read<KelasLogic>();
    final statusText = logic.getStatusDisplay(item);
    final statusColor = logic.getStatusColor(item);

    // --- PERBAIKAN DI SINI ---
    // Kita hapus variabel isSudahAbsen, isTerlambat, dan canEdit
    // agar kode lebih bersih dan tidak ada warning.

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          // No
          Expanded(
            flex: 1,
            child: Text(
              '${item['no'] ?? index}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Nama
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['jam_masuk'] != null)
                  Text(
                    "Masuk: ${item['jam_masuk'].toString().substring(0, 5)}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Aksi (Edit Button)
          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.blue),
                // --- PERBAIKAN TOMBOL ---
                // Hapus pengecekan 'canEdit ? ... : null'
                // Tombol selalu aktif agar guru bisa revisi kesalahan kapan saja
                onPressed: () async {
                  // Navigasi ke EditSiswaScreen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSiswaScreen(
                        siswaId: item['id'],
                        tanggal: DateTime.now(),
                        no: item['no'].toString(),
                        nama: item['nama'],
                        suratUrl: item['file_url'], // URL Surat dari RPC
                      ),
                    ),
                  );
                  // Refresh data setelah kembali
                  if (context.mounted) logic.fetchData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignLeft;

  const _HeaderCell(this.text, {required this.flex, this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 13,
        ),
      ),
    );
  }
}
