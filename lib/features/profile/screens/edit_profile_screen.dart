import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/models/patient.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../provider/profile_provider.dart';
import '../widgets/profile_form.dart';

/// Mengubah profil ([initial] terisi) atau membuat profil baru ([initial] null).
class EditProfileScreen extends StatefulWidget {
  final Patient? initial;

  const EditProfileScreen({super.key, this.initial});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  bool get _isUpdate => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _phoneController.text = initial.phoneNumber ?? '';
      _dateOfBirth = initial.dateOfBirth;
      _gender = initial.gender;
    }
    // Hapus pesan error lama dari percobaan sebelumnya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().clearSaveError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProfileProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final phone = _phoneController.text.trim();
    final dob = _dateOfBirth;

    final Map<String, dynamic> data;
    if (_isUpdate) {
      // PUT menerima nilai null: field yang dikosongkan dikirim sebagai null
      // agar terhapus di server.
      data = {
        'name': _nameController.text.trim(),
        'date_of_birth': dob == null ? null : toApiDate(dob),
        'gender': _gender,
        'phone_number': phone.isEmpty ? null : phone,
      };
    } else {
      data = {
        'name': _nameController.text.trim(),
        if (dob != null) 'date_of_birth': toApiDate(dob),
        if (_gender != null) 'gender': _gender,
        if (phone.isNotEmpty) 'phone_number': phone,
      };
    }

    final success = await provider.savePatientProfile(
      data,
      isUpdate: _isUpdate,
    );
    if (!success || !mounted) return;

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final saving = provider.isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(_isUpdate ? 'Edit Profil' : 'Buat Profil')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileForm(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      dateOfBirth: _dateOfBirth,
                      onDateOfBirthChanged: (value) =>
                          setState(() => _dateOfBirth = value),
                      gender: _gender,
                      onGenderChanged: (value) =>
                          setState(() => _gender = value),
                      enabled: !saving,
                    ),
                    if (provider.saveError != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      InlineNotice(
                        message: provider.saveError!,
                        tone: NoticeTone.danger,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          BottomActionBar(
            child: AppButton(
              label: 'Simpan',
              loading: saving,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
