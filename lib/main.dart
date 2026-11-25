import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// --- Core Imports ---
import 'core/data/provider/auth_api_provider.dart';
import 'core/data/provider/question_api_provider.dart';
import 'core/data/repositories/auth_repository.dart';
import 'core/data/repositories/question_repository.dart';
import 'core/data/repositories/consultation_repository.dart';
import 'core/session/session_manager.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/dio_client.dart';
import 'core/data/provider/consultation_api_provider.dart';
import 'core/data/provider/patient_api_provider.dart';
import 'core/data/repositories/patient_repository.dart';

// --- Feature Imports ---
import 'features/authentication/provider/auth_provider.dart';
import 'features/authentication/screen/splash_screen.dart';
import 'features/profile/provider/profile_provider.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/authentication/screen/login_screen.dart';
import 'features/authentication/screen/register_screen.dart';
import 'features/diagnosis/provider/diagnosis_provider.dart';
import 'features/diagnosis/screens/question_screen.dart';
import 'features/diagnosis/screens/diagnosis_result_screen.dart';
import 'features/home/screen/home_screen.dart';
import 'features/history/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // =================================================================
  // SETUP DEPENDENCIES (DEPENDENCY INJECTION)
  // =================================================================
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Token disimpan di secure storage dan dibagikan ke SessionManager,
  // DioClient, dan AuthProvider (tanpa ketergantungan melingkar).
  final TokenStorage tokenStorage = TokenStorage();
  final SessionManager sessionManager = SessionManager(
    tokenStorage: tokenStorage,
    navigatorKey: navigatorKey,
    messengerKey: messengerKey,
  );

  // Dio memakai validateStatus bawaan (hanya 2xx sukses) agar 4xx menjadi
  // DioException dan dipetakan oleh ApiException.fromDioException.
  final Dio dio = Dio();
  final DioClient dioClient = DioClient(
    dio,
    tokenStorage,
    onUnauthorized: () => sessionManager.expire(),
  );

  // --- Auth Dependencies ---
  final AuthApiProvider authApiProvider = AuthApiProvider(dioClient.dio);
  final AuthRepository authRepository = AuthRepository(authApiProvider);
  final AuthProvider authProvider =
      AuthProvider(authRepository, tokenStorage, sessionManager);

  // --- Diagnosis/Question Dependencies ---
  final QuestionApiProvider questionApiProvider =
      QuestionApiProvider(dioClient.dio);
  final QuestionRepository questionRepository =
      QuestionRepository(questionApiProvider);

  // --- Consultation Dependencies ---
  final ConsultationApiProvider consultationApiProvider =
      ConsultationApiProvider(dioClient.dio);
  final ConsultationRepository consultationRepository =
      ConsultationRepository(consultationApiProvider);

  final DiagnosisProvider diagnosisProvider =
      DiagnosisProvider(questionRepository, consultationRepository);

  // --- Patient Dependencies ---
  final PatientApiProvider patientApiProvider = PatientApiProvider(dioClient.dio);
  final PatientRepository patientRepository = PatientRepository(patientApiProvider);
  final ProfileProvider profileProvider = ProfileProvider(patientRepository);

  // Saat sesi dibersihkan (logout / hapus akun / 401), kosongkan state pengguna.
  sessionManager.addClearListener(profileProvider.clear);
  sessionManager.addClearListener(diagnosisProvider.clear);

  runApp(
    MultiProvider(
      providers: [
        Provider<ConsultationRepository>.value(value: consultationRepository),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DiagnosisProvider>.value(value: diagnosisProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
      ],
      child: MyApp(
        consultationRepository: consultationRepository,
        navigatorKey: navigatorKey,
        messengerKey: messengerKey,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ConsultationRepository consultationRepository;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  const MyApp({
    super.key,
    required this.consultationRepository,
    required this.navigatorKey,
    required this.messengerKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Diagnosis App',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      // Splash memvalidasi token tersimpan lalu menuju /home atau /login
      initialRoute: '/splash',
      // Define all app routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/diagnosis': (context) => const QuestionScreen(),
        '/diagnosis_result': (context) {
          final consultationData = ModalRoute.of(context)?.settings.arguments;
          return DiagnosisResultScreen(consultationData: consultationData);
        },
        '/history': (context) => HistoryScreen(
              consultationRepository: consultationRepository,
            ),
        '/profile': (context) => const ProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
      },
    );
  }
}
