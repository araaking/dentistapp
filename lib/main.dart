import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

// --- Core ---
import 'core/data/provider/auth_api_provider.dart';
import 'core/data/provider/consultation_api_provider.dart';
import 'core/data/provider/patient_api_provider.dart';
import 'core/data/provider/question_api_provider.dart';
import 'core/data/repositories/auth_repository.dart';
import 'core/data/repositories/consultation_repository.dart';
import 'core/data/repositories/patient_repository.dart';
import 'core/data/repositories/question_repository.dart';
import 'core/models/consultation.dart';
import 'core/models/patient.dart';
import 'core/session/session_manager.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/dio_client.dart';

// --- Features ---
import 'features/authentication/provider/auth_provider.dart';
import 'features/authentication/screen/login_screen.dart';
import 'features/authentication/screen/register_screen.dart';
import 'features/authentication/screen/splash_screen.dart';
import 'features/diagnosis/provider/diagnosis_provider.dart';
import 'features/diagnosis/screens/diagnosis_result_screen.dart';
import 'features/diagnosis/screens/question_screen.dart';
import 'features/history/provider/history_provider.dart';
import 'features/home/screen/main_shell.dart';
import 'features/profile/provider/profile_provider.dart';
import 'features/profile/screens/edit_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Tata letak dirancang untuk potret; edge-to-edge dengan ikon sistem gelap.
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);

  // =================================================================
  // SETUP DEPENDENCIES (DEPENDENCY INJECTION)
  // =================================================================
  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  // Token disimpan di secure storage dan dibagikan ke SessionManager,
  // DioClient, dan AuthProvider (tanpa ketergantungan melingkar).
  final tokenStorage = TokenStorage();
  final sessionManager = SessionManager(
    tokenStorage: tokenStorage,
    navigatorKey: navigatorKey,
    messengerKey: messengerKey,
  );

  // Dio memakai validateStatus bawaan (hanya 2xx sukses) agar 4xx menjadi
  // DioException dan dipetakan oleh ApiException.fromDioException.
  final dioClient = DioClient(
    Dio(),
    tokenStorage,
    onUnauthorized: sessionManager.expire,
  );
  final dio = dioClient.dio;

  final authProvider = AuthProvider(
    AuthRepository(AuthApiProvider(dio)),
    tokenStorage,
    sessionManager,
  );

  final consultationRepository = ConsultationRepository(
    ConsultationApiProvider(dio),
  );
  final historyProvider = HistoryProvider(consultationRepository);

  final diagnosisProvider = DiagnosisProvider(
    QuestionRepository(QuestionApiProvider(dio)),
    consultationRepository,
    // Hasil baru langsung muncul di Beranda dan Riwayat.
    onSubmitted: historyProvider.load,
  );

  final profileProvider = ProfileProvider(
    PatientRepository(PatientApiProvider(dio)),
  );

  // Saat sesi dibersihkan (logout / hapus akun / 401), kosongkan seluruh
  // state milik pengguna agar tidak terbawa ke akun berikutnya.
  sessionManager
    ..addClearListener(profileProvider.clear)
    ..addClearListener(historyProvider.clear)
    ..addClearListener(diagnosisProvider.clear);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DiagnosisProvider>.value(
          value: diagnosisProvider,
        ),
        ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ],
      child: DentistApp(navigatorKey: navigatorKey, messengerKey: messengerKey),
    ),
  );
}

class DentistApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  const DentistApp({super.key, this.navigatorKey, this.messengerKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dentist App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: AppTheme.light(),
      // Splash memvalidasi token tersimpan lalu menuju /home atau /login.
      initialRoute: '/splash',
      onGenerateRoute: onGenerateRoute,
    );
  }

  /// Seluruh rute aplikasi. Argumen rute diperiksa tipenya di sini sehingga
  /// layar tidak pernah menerima data berbentuk sembarang.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      '/splash' => const SplashScreen(),
      '/login' => const LoginScreen(),
      '/register' => const RegisterScreen(),
      '/home' => const MainShell(),
      '/diagnosis' => const QuestionScreen(),
      '/diagnosis_result' => DiagnosisResultScreen(
        consultation: args is Consultation ? args : null,
      ),
      '/edit_profile' => EditProfileScreen(
        initial: args is Patient ? args : null,
      ),
      _ => const SplashScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
