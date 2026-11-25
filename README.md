# Dentistapp

Aplikasi mobile (Flutter) untuk pemeriksaan mandiri gangguan sendi rahang (TMD /
*temporomandibular disorder*). Pasien menjawab kuesioner (SQ dan EQ), mengukur
bukaan mulut, dan dapat melampirkan foto; hasil diagnosis disimpan di server
Laravel (`https://dentist.croloze.com/`) dan dapat dilihat kembali di riwayat.

Kontrak API ada di `docs/API.md` pada repositori backend (`backend-dentist`).

## Prasyarat

- Flutter stable **3.32 atau lebih baru** (Dart SDK `^3.8.1`, sesuai `pubspec.yaml`;
  proyek dibuat dengan revisi stable `d7b523b3…` seperti tercatat di `.metadata`).
- Diuji dengan Flutter 3.50.1 (Dart 3.14.0): `flutter analyze` tanpa error/warning,
  `flutter test` 36 test lulus. Masih ada info deprecation yang sengaja ditunda sebagai
  migrasi mendatang: `package:flutter/material.dart` -> material_ui dan `value:` ->
  `initialValue:` pada field form (membutuhkan versi Flutter yang sangat baru).
- Android Studio / Android SDK (untuk Android) dan Xcode (untuk iOS, hanya di macOS).

```bash
flutter pub get
flutter test        # unit test (tidak butuh jaringan)
flutter analyze
```

## Menjalankan aplikasi

### Terhadap server produksi (default)

```bash
flutter run
```

### Terhadap server lokal / staging

URL API dibaca dari `--dart-define=API_BASE_URL=...` (default
`https://dentist.croloze.com/`, diberi garis miring di akhir bila belum ada).

```bash
# Emulator Android -> Laravel di komputer yang sama
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/

# Perangkat fisik di jaringan yang sama
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/

# Build rilis ke staging (HTTPS)
flutter build apk --release --dart-define=API_BASE_URL=https://staging.example.com/
```

**HTTP (cleartext) hanya diizinkan pada build debug Android.** Konfigurasi utama
(`android/app/src/main/res/xml/network_security_config.xml`) melarang HTTP.
Build debug memakai override
`android/app/src/debug/res/xml/network_security_config.xml` yang mengizinkan HTTP
sehingga `http://10.0.2.2:8000/` dapat dipakai saat pengembangan. Build rilis
tidak pernah mengizinkan HTTP. Di iOS, HTTP diblokir oleh App Transport Security;
gunakan HTTPS (mis. tunnel) untuk pengujian di iOS.

## Struktur singkat

- `lib/core` — klien Dio (`utils/dio_client.dart`), pemetaan error
  (`errors/exceptions.dart`), penyimpanan token aman (`storage/token_storage.dart`),
  manajemen sesi (`session/session_manager.dart`), API provider, repository, model.
- `lib/features` — `authentication`, `diagnosis`, `history`, `home`, `profile`
  (provider + layar + widget).
- Arsitektur: *Provider* (state UI) -> *Repository* -> *API provider* (Dio).
- Sesi: token Bearer disimpan di `flutter_secure_storage`; saat aplikasi dibuka,
  layar splash memvalidasi token lewat `GET api/auth/me`. Respons 401 pada request
  terautentikasi menghapus sesi dan mengarahkan pengguna ke layar login.

## Penandatanganan rilis Android

Build rilis membaca `android/key.properties`. Bila file itu tidak ada, build rilis
**fallback ke kunci debug** (hanya untuk `flutter run --release`; jangan diunggah
ke Play Store).

1. Buat keystore (simpan di luar repositori, cadangkan dengan aman):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Buat `android/key.properties` (sudah di-ignore oleh git bersama `*.jks` dan `*.keystore`):

   ```properties
   storePassword=<password keystore>
   keyPassword=<password kunci>
   keyAlias=upload
   storeFile=/path/absolut/ke/upload-keystore.jks
   ```

3. Build:

   ```bash
   flutter build appbundle --release   # untuk Google Play
   flutter build apk --release
   ```

Application ID / namespace Android dan bundle identifier iOS: `com.croloze.dentistapp`.

## iOS

- Buka `ios/Runner.xcworkspace` di Xcode, pilih *Team* untuk signing, lalu
  `flutter build ipa --release`.
- `Info.plist` sudah berisi `NSCameraUsageDescription` (diperlukan `image_picker`; aplikasi hanya memakai kamera).

## Checklist sebelum rilis ke toko

- [ ] Keystore rilis dibuat dan `android/key.properties` terisi (lihat di atas).
- [ ] `versionName`/`versionCode` dinaikkan lewat `version:` di `pubspec.yaml`.
- [ ] Build memakai HTTPS ke server produksi (tanpa `API_BASE_URL` atau dengan URL HTTPS).
- [ ] Ikon aplikasi dan splash final menggantikan ikon bawaan Flutter.
- [ ] Hapus akun berfungsi (Profil -> Hapus Akun) — wajib untuk App Store / Google Play.
- [ ] Kebijakan privasi (data kesehatan dan foto) tersedia dan ditautkan di listing toko;
      isi formulir *Data safety* (Google Play) dan *App Privacy* (App Store).
- [ ] Uji di perangkat nyata: login, sesi bertahan setelah aplikasi ditutup, kamera
      (Android dan iOS), pengiriman diagnosis dengan dan tanpa foto, foto > 5 MB ditolak.
- [ ] Jalankan `flutter analyze` dan `flutter test` tanpa error.
- [ ] Tidak ada rahasia (kunci, `key.properties`, `.jks`) di repositori.

## Pembaruan dependensi (tertunda)

Versi dependensi di `pubspec.yaml`/`pubspec.lock` sengaja belum diubah. Pembaruan,
misalnya `audioplayers` 5.2.1 -> 6.x, membutuhkan `flutter pub upgrade` dan pengujian
manual (khususnya pemutaran contoh suara E3 di Android dan iOS), sehingga dikerjakan
terpisah.
