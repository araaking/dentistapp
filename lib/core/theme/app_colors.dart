import 'package:material_ui/material_ui.dart';

/// Palet warna Dentist App ("rose" hangat di atas latar netral).
///
/// [primary] sengaja lebih gelap dari versi lama (#B66878) agar teks putih di
/// atas tombol dan teks berwarna di atas latar putih lolos kontras WCAG AA.
class AppColors {
  const AppColors._();

  // Merek
  static const Color primary = Color(0xFFA85769);
  static const Color primaryDark = Color(0xFF8A4254);
  static const Color primarySoft = Color(0xFFF6E5E8); // latar pilihan aktif
  static const Color primaryTint = Color(
    0xFFFBF2F4,
  ); // latar ikon / kartu lembut

  // Permukaan
  static const Color background = Color(0xFFFCF9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEADFE2);

  // Teks
  static const Color textPrimary = Color(0xFF2B2126);
  static const Color textSecondary = Color(0xFF6E6368);
  static const Color textMuted = Color(0xFF9A8F94);

  // Status
  static const Color success = Color(0xFF2E7D5B);
  static const Color successSoft = Color(0xFFE6F3EC);
  static const Color warning = Color(0xFF9A6410);
  static const Color warningSoft = Color(0xFFFBF1DC);
  static const Color danger = Color(0xFFB93A32);
  static const Color dangerSoft = Color(0xFFFBE9E7);
}
