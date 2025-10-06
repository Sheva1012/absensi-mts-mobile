import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_absensi_mts/Mobile/auth.dart'; 

void main() async {
  // Pastikan Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://eachbhkjgadrpmrpbwat.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2hiaGtqZ2FkcnBtcnBid2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2Njk1MDEsImV4cCI6MjA3NTI0NTUwMX0.gZPdf88neU4yuLdKkUlTKNadpsRArxUp2IlQHk-XCrI',
  );

  runApp(const MyApp());
}


final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Absensi MTS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
    );
  }
}

