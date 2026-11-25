import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Form data diri pasien. Dipakai oleh layar Edit Profil dan Registrasi.
/// Bila [nameController] null, kolom nama tidak ditampilkan (Registrasi sudah
/// memiliki kolom nama sendiri).
class ProfileForm extends StatelessWidget {
  final TextEditingController? nameController;
  final TextEditingController dateOfBirthController;
  final TextEditingController phoneController;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;

  const ProfileForm({
    super.key,
    this.nameController,
    required this.dateOfBirthController,
    required this.phoneController,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (nameController != null) ...[
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: dateOfBirthController,
          builder: (context, value, child) {
            return TextFormField(
              controller: dateOfBirthController,
              decoration: InputDecoration(
                labelText: 'Tanggal Lahir',
                border: const OutlineInputBorder(),
                suffixIcon: value.text.isEmpty
                    ? const Icon(Icons.calendar_today)
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Kosongkan tanggal lahir',
                        onPressed: () => dateOfBirthController.clear(),
                      ),
              ),
              readOnly: true,
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(value.text) ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (selectedDate != null) {
                  // Format untuk backend: YYYY-MM-DD
                  dateOfBirthController.text =
                      '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                }
              },
            );
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(selectedGender),
          initialValue: selectedGender,
          decoration: const InputDecoration(
            labelText: 'Jenis Kelamin',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Tidak diisi')),
            DropdownMenuItem<String>(value: 'Male', child: Text('Laki-laki')),
            DropdownMenuItem<String>(value: 'Female', child: Text('Perempuan')),
          ],
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Nomor Telepon',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          keyboardType: TextInputType.phone,
          maxLength: 15,
          inputFormatters: [LengthLimitingTextInputFormatter(15)],
        ),
      ],
    );
  }
}
