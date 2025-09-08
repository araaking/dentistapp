import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController dateOfBirthController;
  final TextEditingController phoneController;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;

  const ProfileForm({
    super.key,
    required this.nameController,
    required this.dateOfBirthController,
    required this.phoneController,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama harus diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: dateOfBirthController,
          decoration: const InputDecoration(
            labelText: 'Tanggal Lahir',
            border: OutlineInputBorder(),
          ),
          readOnly: true,
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              // Format untuk backend: YYYY-MM-DD
              dateOfBirthController.text =
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedGender,
          decoration: const InputDecoration(
            labelText: 'Jenis Kelamin',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Female', child: Text('Perempuan')),
          ],
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Nomor Telepon',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
