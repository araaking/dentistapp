import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../history/provider/history_provider.dart';
import '../../history/screens/history_screen.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

/// Kerangka utama setelah login: tiga tab (Beranda, Riwayat, Profil).
///
/// Navigasi bawah hanya berpindah tab. Aksi seperti memulai pemeriksaan atau
/// keluar akun tidak diletakkan di sini agar tidak terpicu tanpa sengaja.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _homeTab = 0;
  static const int _historyTab = 1;
  static const int _profileTab = 2;

  int _index = _homeTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() {
    return Future.wait([
      context.read<ProfileProvider>().loadPatientProfile(),
      context.read<HistoryProvider>().load(),
    ]);
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _startDiagnosis() {
    Navigator.of(context).pushNamed('/diagnosis');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali di tab lain membawa pengguna ke Beranda dulu.
      canPop: _index == _homeTab,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _select(_homeTab);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              onStartDiagnosis: _startDiagnosis,
              onOpenHistory: () => _select(_historyTab),
              onOpenProfile: () => _select(_profileTab),
              onRefresh: _refresh,
            ),
            HistoryScreen(onStartDiagnosis: _startDiagnosis),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
