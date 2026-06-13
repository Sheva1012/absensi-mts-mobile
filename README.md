# Absensi MTS Mobile - Student Attendance Application

Absensi MTS Mobile adalah aplikasi berbasis mobile yang digunakan untuk membantu proses absensi siswa secara digital.

Aplikasi ini digunakan oleh guru dan siswa agar proses pencatatan serta monitoring kehadiran dapat dilakukan lebih cepat dan terintegrasi dengan sistem.


## About Project

Project ini merupakan aplikasi mobile dari Sistem Informasi Absensi MTS.

Aplikasi mobile digunakan oleh guru untuk melakukan absensi siswa secara langsung, sedangkan siswa dapat melihat informasi data kehadiran melalui aplikasi.

Data aplikasi mobile terhubung dengan sistem admin web menggunakan database online.


## Features

Guru:
- Login aplikasi
- Melihat daftar kelas
- Melihat daftar siswa
- Melakukan absensi siswa
- Mengubah status kehadiran
- Melihat riwayat absensi


Siswa:
- Login aplikasi
- Melihat profil siswa
- Melihat informasi kelas
- Melihat data kehadiran
- Melihat riwayat absensi


## Attendance Status

Jenis status absensi:

- Hadir
- Izin
- Sakit
- Alpha


## System Flow

Guru:

1. Guru login aplikasi
2. Memilih kelas
3. Melihat daftar siswa
4. Input status kehadiran
5. Data tersimpan ke database


Siswa:

1. Siswa login aplikasi
2. Sistem mengambil data siswa
3. Siswa melihat informasi absensi


## Technology Used

- Flutter
- Dart
- Supabase
- PostgreSQL Database
- Android SDK


## Platform Support

- Android
- iOS


## Installation

Clone repository

```bash
git clone https://github.com/Sheva1012/absensi-mts-mobile.git
```

Masuk folder project

```bash
cd absensi-mts-mobile
```

Install dependency

```bash
flutter pub get
```

Konfigurasi environment

```env
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

Menjalankan aplikasi

```bash
flutter run
```


## Database

Database:
Supabase PostgreSQL

Main Table:
- Users
- Students
- Teachers
- Classes
- Attendance


## Related Project

Admin Website:

absensi-mts-admin-web


## Developer

Sheva Adrian

Github:
https://github.com/Sheva1012


## License

Project ini dibuat sebagai aplikasi mobile pendukung sistem informasi absensi sekolah.
