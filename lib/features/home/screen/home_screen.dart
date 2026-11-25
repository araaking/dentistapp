import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/repositories/consultation_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../diagnosis/provider/diagnosis_provider.dart';
import '../../profile/provider/profile_provider.dart';
import '../../authentication/provider/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Riwayat terbaru (maks. 3) dari API
  List<dynamic> _latestConsultations = [];
  bool _historyLoading = true;
  String? _historyError;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Diagnosis
        _startDiagnosis();
        break;
      case 1: // Profil
        _openRoute('/profile');
        break;
      case 2: // LogOut
        _handleLogout();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    // Reset index ke 0 setiap kali kembali ke home screen
    _selectedIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Muat profil agar header menampilkan nama pasien yang sebenarnya.
      context.read<ProfileProvider>().loadPatientProfile();
      _loadHistory();
    });
  }

  /// Membuka rute lalu menyegarkan data saat kembali ke Beranda.
  void _openRoute(String route, {Object? arguments}) {
    Navigator.of(context).pushNamed(route, arguments: arguments).then((_) {
      if (!mounted) return;
      setState(() => _selectedIndex = 0);
      _loadHistory();
    });
  }

  void _startDiagnosis() {
    // Reset diagnosis state sebelum memulai diagnosis baru
    context.read<DiagnosisProvider>().resetDiagnosis();
    _openRoute('/diagnosis');
  }

  Future<void> _loadHistory() async {
    final repository = context.read<ConsultationRepository>();
    if (mounted) {
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });
    }
    try {
      final consultations = await repository.getConsultations();
      if (!mounted) return;
      setState(() {
        _latestConsultations = consultations.take(3).toList();
        _historyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = ApiException.messageOf(e);
        _historyLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    // Menghapus token + seluruh state pengguna (profil, diagnosis).
    await authProvider.logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ProfileProvider>().loadPatientProfile();
            await _loadHistory();
          },
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMainCard(context),
              const SizedBox(height: 24),
              _buildHealthNeeds(),
              const SizedBox(height: 24),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rtl),
            label: 'Diagnosis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'LogOut',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final patientName = profileProvider.patientData?['name'] ?? 'User';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $patientName!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bagaimana perasaanmu hari ini?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.icon, size: 28),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.icon, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Siap untuk konsultasi?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jawab beberapa pertanyaan untuk mengetahui kondisi Anda.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startDiagnosis,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mulai Diagnosis Baru'),
          )
        ],
      ),
    );
  }

  Widget _buildHealthNeeds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMenuIcon(Icons.checklist_rtl, 'Diagnosis', _startDiagnosis),
            _buildMenuIcon(Icons.history, 'Riwayat', () => _openRoute('/history')),
            _buildMenuIcon(Icons.person_outline, 'Profil', () => _openRoute('/profile')),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softPinkAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.icon, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Diagnosis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _openRoute('/history'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildHistoryContent(),
      ],
    );
  }

  List<Widget> _buildHistoryContent() {
    if (_historyLoading && _latestConsultations.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ];
    }

    if (_historyError != null && _latestConsultations.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat riwayat:\n$_historyError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ];
    }

    if (_latestConsultations.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Column(
            children: [
              Icon(Icons.history_toggle_off, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Belum ada riwayat diagnosis',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final consultation in _latestConsultations) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_buildHistoryItem(consultation));
    }
    return widgets;
  }

  Widget _buildHistoryItem(dynamic consultation) {
    String diagnosis = 'Tidak ada diagnosis';
    if (consultation is Map && consultation['diagnoses'] is List) {
      final names = (consultation['diagnoses'] as List).map((d) {
        if (d is Map && d['name'] != null) return d['name'].toString();
        return d.toString();
      }).toList();
      if (names.isNotEmpty) diagnosis = names.first;
    }
    final date = formatDateId(
      consultation is Map ? consultation['consultation_date'] : null,
    );

    return InkWell(
      onTap: () => _openRoute('/diagnosis_result', arguments: consultation),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diagnosis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
