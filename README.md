# Dentist App

Aplikasi mobile (Flutter) untuk pemeriksaan mandiri gangguan sendi rahang (TMD /
*temporomandibular disorder*). Pasien menjawab kuesioner (SQ dan EQ), mengukur
bukaan mulut, dan dapat melampirkan foto; hasil diagnosis disimpan di server
Laravel (`https://dentist.croloze.com/`) dan dapat dilihat kembali di riwayat.

Kontrak API ada di `docs/API.md` pada repositori backend (`backend-dentist`).

## Prasyarat

- Flutter stable **3.50.0 atau lebih baru** (Dart SDK `^3.13.0`; keduanya dipaksa oleh
  `environment` di `pubspec.yaml`, sehingga build di Flutter lama gagal dengan pesan jelas).
  Material memakai paket pub `material_ui` (pengganti `package:flutter/material.dart`).
- Diuji dengan Flutter 3.50.1 (Dart 3.14.0): `flutter analyze` -> No issues found,
  `flutter test` semua lulus.
- Dependensi sudah diperbarui ke versi terbaru: `audioplayers` 6.8.x,
  `flutter_secure_storage` 11.x, `dio` 5.11.x, `image_picker` 1.2.4, `cupertino_icons` 2.x,
  `flutter_lints` 6.x, `material_ui` 1.11.x.
- iOS 13.0 atau lebih baru; Android minSdk 24 (`flutter.minSdkVersion`). Toolchain Android
  mengikuti template Flutter 3.50: AGP 9.3.1, Kotlin 2.4.20, Gradle 9.5.0, target Java 17. Build Android butuh JDK 21 (lint AGP 9.3 memakai API Java 21).
- Catatan upgrade: `flutter_secure_storage` 9 -> 11 mengganti algoritma enkripsi Android,
  sehingga token login lama tidak terbaca; aplikasi menganggapnya belum login dan
  pengguna cukup masuk ulang.
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
  manajemen sesi (`session/session_manager.dart`), API provider, repository,
  model bertipe (`models/`: `Consultation`, `Patient`, `QuestionModel`).
- `lib/core/theme` — design system: `app_colors.dart` (palet), `app_theme.dart`
  (tema Material 3, jarak, gaya tombol/input). `lib/core/widgets` berisi komponen
  bersama (`AppCard`, `AppButton`, `InlineNotice`, `StateView`, `BottomActionBar`,
  `AppLogo`). Layar baru sebaiknya memakai komponen ini, bukan warna/gaya sendiri.
- `lib/features` — `authentication`, `diagnosis`, `history`, `home`, `profile`
  (provider + layar + widget).
- Arsitektur: *Provider* (state UI) -> *Repository* -> *API provider* (Dio).
- Navigasi: `/home` adalah `MainShell` dengan tiga tab (Beranda, Riwayat, Profil).
  Rute didaftarkan di `DentistApp.onGenerateRoute` (`lib/main.dart`).
- Sesi: token Bearer disimpan di `flutter_secure_storage`; saat aplikasi dibuka,
  layar splash memvalidasi token lewat `GET api/auth/me`. Respons 401 pada request
  terautentikasi menghapus sesi dan mengarahkan pengguna ke layar masuk.

## Alur pemeriksaan

- Pertanyaan diambil dari `GET api/questions` dan ditampilkan sebagai satu urutan
  langkah (SQ lalu EQ) dengan satu bilah kemajuan.
- **Tidak ada jawaban yang terisi otomatis.** Nilai `input.default` dari server
  tidak dipakai sebagai pilihan awal; setiap langkah wajib dijawab pengguna.
- **Pertanyaan lanjutan dilewati bila tidak relevan**: SQ2-SQ4 hanya ditanyakan
  bila SQ1 = "Ya", SQ6-SQ7 hanya bila SQ5 = "Ya" (`DiagnosisProvider.followUpOf`).
  Pertanyaan yang dilewati tidak dikirim; server memakai nilai defaultnya sehingga
  hasil diagnosis sama dengan menjawab "tidak". Kosongkan map tersebut bila semua
  pertanyaan harus selalu ditanyakan.
- Teks tampilan (judul tanpa "(Jawaban: ...)", label opsi, nama area, petunjuk)
  diatur di `features/diagnosis/question_presenter.dart`. Nilai yang dikirim ke
  server tidak diubah.
- Nama diagnosis dari server diterjemahkan untuk tampilan di
  `core/utils/diagnosis_info.dart`.

## Alat bantu desain

Di luar folder `test/`, jadi tidak ikut `flutter test` biasa:

```bash
# Merender layar utama dengan data palsu ke tool/screenshots/out/*.png
flutter test tool/screenshots/render_screens_test.dart

# Membuat ulang ikon aplikasi lalu memasangnya ke Android/iOS/web (macOS)
flutter test tool/icons/render_icons_test.dart && tool/icons/install_icons.sh
```

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
