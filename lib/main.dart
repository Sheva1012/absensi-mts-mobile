import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi format tanggal

// Sesuaikan path import ini dengan nama file asli kamu
import 'mobile/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Format Tanggal Indonesia (Penting untuk intl)
  await initializeDateFormatting('id_ID', null);

  // 2. Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://eachbhkjgadrpmrpbwat.supabase.co',
    // ⚠️ WAJIB ISI: Copy dari Supabase Dashboard -> Settings -> API -> anon public
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2hiaGtqZ2FkcnBtcnBid2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2Njk1MDEsImV4cCI6MjA3NTI0NTUwMX0.gZPdf88neU4yuLdKkUlTKNadpsRArxUp2IlQHk-XCrI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Absensi MTS',

      // 3. Gunakan Material 3 agar tampilan lebih modern & konsisten
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6CB0), // Warna biru brand sekolah
          brightness: Brightness.light,
        ),
        // Font default (opsional, jika ingin font Google)
        // fontFamily: 'Nunito',
      ),

      // 4. Konfigurasi Bahasa Indonesia (Penting untuk DatePicker)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
      ],
      locale: const Locale('id', 'ID'), // Paksa default ke Indonesia
      // Halaman Awal
      home: const AuthWrapper(),
    );
  }
}
