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
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name']?.toString() ?? '';
      _dateOfBirthController.text = widget.initialData!['date_of_birth']?.toString() ?? '';
      _phoneController.text = widget.initialData!['phone_number']?.toString() ?? '';
      _selectedGender = widget.initialData!['gender']?.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ProfileProvider>();
      final data = {
        'name': _nameController.text,
        if (_dateOfBirthController.text.isNotEmpty) 'date_of_birth': _dateOfBirthController.text,
        if (_selectedGender != null) 'gender': _selectedGender,
        if (_phoneController.text.isNotEmpty) 'phone_number': _phoneController.text,
      };

      final success = widget.initialData != null
          ? await provider.updatePatientProfile(data)
          : await provider.createPatientProfile(data);

      if (success && mounted) {
        Navigator.of(context).pop();
      }
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
          return Padding(
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
