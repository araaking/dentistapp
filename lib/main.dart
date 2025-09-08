import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// --- Core Imports ---
import 'core/data/provider/auth_api_provider.dart';
import 'core/data/provider/question_api_provider.dart';
import 'core/data/repositories/auth_repository.dart';
import 'core/data/repositories/question_repository.dart';
import 'core/data/repositories/consultation_repository.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/dio_client.dart';
import 'core/data/provider/consultation_api_provider.dart';

// --- Feature Imports ---
import 'features/authentication/provider/auth_provider.dart';
import 'features/authentication/screen/login_screen.dart';
import 'features/authentication/screen/register_screen.dart';
import 'features/diagnosis/provider/diagnosis_provider.dart';
import 'features/diagnosis/screens/question_screen.dart';
import 'features/diagnosis/screens/diagnosis_result_screen.dart';
import 'features/home/screen/home_screen.dart';
import 'features/history/screens/history_screen.dart';

void main() {
  // =================================================================
  // SETUP DEPENDENCIES (DEPENDENCY INJECTION)
  // =================================================================
  final Dio dio = Dio();
  dio.options.followRedirects = true;
  dio.options.validateStatus = (status) {
    return status! < 500;
  };

  // --- Auth Dependencies ---\n  // Layer 3: API Provider (Talks to the internet)
  final AuthApiProvider authApiProvider = AuthApiProvider(dio);
  // Layer 2: Repository (Processes data)
  final AuthRepository authRepository = AuthRepository(authApiProvider);
  final AuthProvider authProvider = AuthProvider(authRepository);

  // --- DioClient now depends on AuthProvider to get the token ---
  final DioClient dioClient = DioClient(dio, authProvider);

  // --- Diagnosis/Question Dependencies ---\n  // Layer 3: API Provider
  final QuestionApiProvider questionApiProvider =
      QuestionApiProvider(dioClient.dio);
  // Layer 2: Repository
  final QuestionRepository questionRepository =
      QuestionRepository(questionApiProvider);

  // --- Consultation Dependencies ---
  final ConsultationApiProvider consultationApiProvider =
      ConsultationApiProvider(dioClient.dio);
  final ConsultationRepository consultationRepository =
      ConsultationRepository(consultationApiProvider);

  runApp(
    MultiProvider(
      providers: [
        // Layer 1: Provider (Manages State for UI) - For Authentication
        ChangeNotifierProvider.value(
          value: authProvider,
        ),
        // Layer 1: Provider (Manages State for UI) - For Diagnosis
        ChangeNotifierProvider(
          create: (_) => DiagnosisProvider(questionRepository, consultationRepository),
        ),
      ],
      child: MyApp(consultationRepository: consultationRepository),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ConsultationRepository consultationRepository;

  const MyApp({super.key, required this.consultationRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Diagnosis App',
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
      // Set initial route
      initialRoute: '/login',
      // Define all app routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(), 
        '/diagnosis': (context) => const QuestionScreen(),
        '/diagnosis_result': (context) {
          final consultationData = ModalRoute.of(context)?.settings.arguments;
          return DiagnosisResultScreen(
            consultationRepository: consultationRepository,
            consultationData: consultationData,
          );
        },
        '/history': (context) => HistoryScreen(
              consultationRepository: consultationRepository,
            ),
      },
    );
  }
}
