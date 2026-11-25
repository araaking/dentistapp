import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';

/// Kolom data diri pasien. Dipakai oleh layar Edit Profil dan Registrasi.
/// Bila [nameController] null, kolom nama tidak ditampilkan (Registrasi sudah
/// memiliki kolom nama sendiri).
class ProfileForm extends StatelessWidget {
  final TextEditingController? nameController;
  final TextEditingController phoneController;
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onDateOfBirthChanged;

  /// `Male`, `Female`, atau null (tidak diisi).
  final String? gender;
  final ValueChanged<String?> onGenderChanged;
  final bool enabled;

  const ProfileForm({
    super.key,
    this.nameController,
    required this.phoneController,
    required this.dateOfBirth,
    required this.onDateOfBirthChanged,
    required this.gender,
    required this.onGenderChanged,
    this.enabled = true,
  });

  static String? validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama harus diisi.';
    if (text.length > 255) return 'Nama terlalu panjang.';
    return null;
  }

  /// Nomor telepon opsional; bila diisi minimal 8 digit dan maksimal 15
  /// karakter (batas server), boleh diawali +.
  static String? validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    final validChars = RegExp(r'^\+?[0-9()\-\s]+$').hasMatch(text);
    if (!validChars || digits < 8 || text.length > 15) {
      return 'Masukkan nomor telepon yang valid, mis. 081234567890.';
    }
    return null;
  }

  Future<void> _pickDate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      fieldLabelText: 'Tanggal lahir',
    );
    if (selected != null) onDateOfBirthChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nameController != null) ...[
          TextFormField(
            controller: nameController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: validateName,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Semantics(
          button: true,
          label: 'Tanggal lahir',
          child: InkWell(
            onTap: enabled ? () => _pickDate(context) : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            child: InputDecorator(
              isEmpty: dateOfBirth == null,
              decoration: InputDecoration(
                labelText: 'Tanggal lahir',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: dateOfBirth == null
                    ? const Icon(Icons.calendar_today_outlined, size: 20)
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Kosongkan tanggal lahir',
                        onPressed: enabled
                            ? () => onDateOfBirthChanged(null)
                            : null,
                      ),
              ),
              // Teks kosong menjaga tinggi kolom sama dengan kolom lain.
              child: Text(
                dateOfBirth == null ? '' : formatCalendarDateId(dateOfBirth),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Jenis kelamin', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _GenderChoice(
                label: 'Laki-laki',
                selected: gender == 'Male',
                onTap: enabled
                    ? () => onGenderChanged(gender == 'Male' ? null : 'Male')
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _GenderChoice(
                label: 'Perempuan',
                selected: gender == 'Female',
                onTap: enabled
                    ? () =>
                          onGenderChanged(gender == 'Female' ? null : 'Female')
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: phoneController,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: const InputDecoration(
            labelText: 'Nomor telepon',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: validatePhone,
        ),
      ],
    );
  }
}

class _GenderChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _GenderChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusSm + 2);
    return Semantics(
      button: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
