import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/profile_provider.dart';
import '../widgets/profile_form.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const EditProfileScreen({super.key, this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _nameController.text = initial['name']?.toString() ?? '';
      _dateOfBirthController.text = initial['date_of_birth']?.toString() ?? '';
      _phoneController.text = initial['phone_number']?.toString() ?? '';
      _selectedGender = initial['gender']?.toString();
    }
    // Hapus pesan error lama dari layar sebelumnya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    final isUpdate = widget.initialData != null;

    final dateOfBirth = _dateOfBirthController.text.trim();
    final phone = _phoneController.text.trim();

    final Map<String, dynamic> data;
    if (isUpdate) {
      // PUT menerima nilai null: field yang dikosongkan dikirim sebagai null
      // agar terhapus di server.
      data = {
        'name': _nameController.text.trim(),
        'date_of_birth': dateOfBirth.isEmpty ? null : dateOfBirth,
        'gender': _selectedGender,
        'phone_number': phone.isEmpty ? null : phone,
      };
    } else {
      data = {
        'name': _nameController.text.trim(),
        if (dateOfBirth.isNotEmpty) 'date_of_birth': dateOfBirth,
        if (_selectedGender != null) 'gender': _selectedGender,
        if (phone.isNotEmpty) 'phone_number': phone,
      };
    }

    final success = isUpdate
        ? await provider.updatePatientProfile(data)
        : await provider.createPatientProfile(data);

    if (success && mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData != null ? 'Edit Profil' : 'Buat Profil'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ProfileForm(
                    nameController: _nameController,
                    dateOfBirthController: _dateOfBirthController,
                    phoneController: _phoneController,
                    selectedGender: _selectedGender,
                    onGenderChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (provider.isLoading)
                    const CircularProgressIndicator(color: AppColors.primary)
                  else
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: const Text('Simpan Profil'),
                    ),
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
