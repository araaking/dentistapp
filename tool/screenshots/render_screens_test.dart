// Alat bantu desain: merender layar utama dengan data palsu ke PNG di
// `tool/screenshots/out/` (tanpa emulator dan tanpa jaringan).
//
//   flutter test tool/screenshots/render_screens_test.dart
//
// Tidak ikut `flutter test` biasa karena berada di luar folder `test/`.
import 'dart:io';

import 'package:dentistapp/core/data/consultation_payload.dart';
import 'package:dentistapp/core/data/repositories/auth_repository.dart';
import 'package:dentistapp/core/data/repositories/consultation_repository.dart';
import 'package:dentistapp/core/data/repositories/patient_repository.dart';
import 'package:dentistapp/core/data/repositories/question_repository.dart';
import 'package:dentistapp/core/models/consultation.dart';
import 'package:dentistapp/core/models/patient.dart';
import 'package:dentistapp/core/models/question_model.dart';
import 'package:dentistapp/core/session/session_manager.dart';
import 'package:dentistapp/core/storage/token_storage.dart';
import 'package:dentistapp/features/authentication/provider/auth_provider.dart';
import 'package:dentistapp/features/diagnosis/provider/diagnosis_provider.dart';
import 'package:dentistapp/features/history/provider/history_provider.dart';
import 'package:dentistapp/features/profile/provider/profile_provider.dart';
import 'package:dentistapp/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

const Size _phone = Size(360, 780);
const double _dpr = 2;

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Map<String, dynamic>> getMe() async => {
    'id': 1,
    'email': 'alfian@example.com',
  };

  @override
  Future<Map<String, dynamic>> login(String email, String password) async => {
    'token': 't',
    'user': {'email': email},
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePatientRepository implements PatientRepository {
  @override
  Future<Patient?> getPatient() async => Patient(
    name: 'Alfian Dimas',
    dateOfBirth: DateTime(2000, 8, 11),
    gender: 'Male',
    phoneNumber: '081234567890',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConsultationRepository implements ConsultationRepository {
  List<Consultation> history = [
    Consultation(
      id: 3,
      date: DateTime(2026, 11, 25, 10, 43),
      diagnoses: const ['Joint-related TMD'],
    ),
    Consultation(
      id: 2,
      date: DateTime(2026, 11, 2, 19, 5),
      diagnoses: const ['No specific TMD diagnosis found.'],
    ),
    Consultation(
      id: 1,
      date: DateTime(2026, 10, 14, 8, 30),
      diagnoses: const ['Myalgia'],
    ),
  ];

  @override
  Future<List<Consultation>> getConsultationHistory() async => history;

  @override
  Future<Consultation> submitConsultation(ConsultationPayload payload) async =>
      Consultation(
        id: 9,
        date: DateTime(2026, 11, 25, 10, 43),
        diagnoses: const ['Joint-related TMD'],
      );
}

class _FakeQuestionRepository implements QuestionRepository {
  @override
  Future<AllQuestionsModel> getQuestions() async =>
      AllQuestionsModel.fromJson(_questions());
}

/// Sama dengan `TmdQuestionnaire::apiPayload()` di backend.
Map<String, dynamic> _questions() {
  Map<String, dynamic> q(
    String code,
    String text, [
    List<String> options = const ['Ya', 'Tidak'],
    String type = 'radio',
  ]) => {
    'code': code,
    'text': text,
    'input': {'type': type, 'options': options, 'default': options.last},
  };
  const areas = ['Temporalis', 'Masseter', 'TMJ'];
  const labels = [
    '0 - Tidak Nyeri',
    '1 - Nyeri Ringan',
    '2 - Nyeri Sedang',
    '3 - Nyeri Berat',
  ];
  Map<String, dynamic> scores(String code, String text) => {
    'code': code,
    'text': text,
    'input': {
      'type': 'group_select_scores',
      'areas': areas,
      'min': 0,
      'max': 3,
      'labels': labels,
    },
  };
  return {
    'sq': [
      q('SQ1', 'Apakah Anda merasakan nyeri di rahang, pelipis, atau telinga?'),
      q(
        'SQ2',
        'Berapa lama nyeri di rahang/pelipis/telinga berlangsung? (Jawaban: < 1 minggu atau >= 1 minggu)',
        ['< 1 minggu', '>= 1 minggu'],
      ),
      q('SQ3', 'Bagaimana sifat nyeri? Apakah persisten atau kambuhan?'),
      q(
        'SQ4',
        'Apakah aktivitas (mengunyah makanan keras, membuka mulut lebar, kebiasaan rahang, aktivitas rahang lain) memengaruhi rasa sakit?',
      ),
      q('SQ5', 'Apakah Anda mengalami sakit kepala di pelipis?'),
      q(
        'SQ6',
        'Berapa lama sakit kepala itu berlangsung? (Jawaban: < 1x/minggu atau >= 1x/minggu)',
        ['< 1x/minggu', '>= 1x/minggu', 'Tidak'],
      ),
      q('SQ7', 'Apakah aktivitas rahang mengubah sakit kepala Anda?'),
      q(
        'SQ8',
        'Apakah Anda mendengar bunyi pada rahang? (Jawaban: Tidak ada, Sesekali, Sering)',
        ['Tidak ada', 'Sesekali', 'Sering'],
        'select',
      ),
      q(
        'SQ9',
        'Apakah rahang Anda pernah terkunci sehingga tidak bisa terbuka penuh?',
      ),
      q(
        'SQ10',
        'Apakah rahang pernah terkunci parah sehingga mulut tidak bisa terbuka dan makan terganggu?',
      ),
      q(
        'SQ11',
        'Apakah rahang pernah terkunci sehingga tidak bisa terbuka walau sebentar?',
      ),
      q('SQ12', 'Apakah sekarang rahang terkunci sehingga pembukaan terbatas?'),
      q(
        'SQ13',
        'Apakah pernah mengalami rahang terkunci dalam posisi terbuka sehingga tidak bisa menutup?',
      ),
      q(
        'SQ14',
        'Apakah Anda harus memanipulasi/ menggeser rahang agar bisa menutup kembali setelah terbuka?',
      ),
    ],
    'eq': [
      scores('E1', 'Pemeriksaan Nyeri Tekan Ringan'),
      {
        'code': 'E2',
        'text': 'Pengukuran Bukaan Mulut Maksimal',
        'input': {'type': 'composite'},
      },
      {
        'code': 'E3',
        'text': 'Pemeriksaan Bunyi Sendi Rahang',
        'input': {
          'type': 'radio',
          'default': 'Tidak ada',
          'options': [
            {'value': 'Tidak ada', 'label': 'Tidak ada bunyi'},
            {
              'value': 'Kliking',
              'label': 'Bunyi kliking',
              'audio': 'https://x/sounds/kliktunggaldanganda.wav',
            },
            {
              'value': 'Krepitasi',
              'label': 'Bunyi kasar seperti pasir (krepitasi)',
              'audio': 'https://x/sounds/krepitasi.wav',
            },
          ],
        },
      },
      scores('E4', 'Pemeriksaan Nyeri Tekan Lebih Dalam'),
    ],
  };
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.view((await File('$dir/$name').readAsBytes()).buffer);

  final roboto = FontLoader('Roboto');
  for (final f in const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Italic.ttf',
  ]) {
    roboto.addFont(read(f));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

class _Harness {
  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final consultations = _FakeConsultationRepository();
  late final AuthProvider auth;
  late final HistoryProvider history;
  late final DiagnosisProvider diagnosis;
  late final ProfileProvider profile;

  _Harness() {
    final storage = TokenStorage();
    final session = SessionManager(
      tokenStorage: storage,
      navigatorKey: navigatorKey,
      messengerKey: messengerKey,
    );
    auth = AuthProvider(_FakeAuthRepository(), storage, session);
    history = HistoryProvider(consultations);
    diagnosis = DiagnosisProvider(
      _FakeQuestionRepository(),
      consultations,
      onSubmitted: history.load,
    );
    profile = ProfileProvider(_FakePatientRepository());
  }

  Widget app(String route, {Object? arguments}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<DiagnosisProvider>.value(value: diagnosis),
        ChangeNotifierProvider<HistoryProvider>.value(value: history),
        ChangeNotifierProvider<ProfileProvider>.value(value: profile),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: messengerKey,
        theme: DentistApp(navigatorKey: navigatorKey)
            .build(navigatorKey.currentContext ?? _dummy)
            .theme,
        onGenerateInitialRoutes: (_) => [
          DentistApp.onGenerateRoute(
            RouteSettings(name: route, arguments: arguments),
          )!,
        ],
        onGenerateRoute: DentistApp.onGenerateRoute,
      ),
    );
  }
}

// Konteks hanya dipakai untuk mengambil tema dari DentistApp.build.
late BuildContext _dummy;

extension on Widget {
  ThemeData? get theme => (this as MaterialApp).theme;
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    autoUpdateGoldenFiles = true;
  });
  setUp(() => debugDisableShadows = false);

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/$name.png'),
    );
  }

  Future<_Harness> start(
    WidgetTester tester,
    String route, {
    Object? arguments,
  }) async {
    tester.view.physicalSize = _phone * _dpr;
    tester.view.devicePixelRatio = _dpr;
    // Meniru status bar dan navigation bar 3 tombol Android.
    tester.view.padding = const FakeViewPadding(
      top: 28 * _dpr,
      bottom: 48 * _dpr,
    );
    tester.view.viewPadding = const FakeViewPadding(
      top: 28 * _dpr,
      bottom: 48 * _dpr,
    );
    addTearDown(tester.view.reset);
    addTearDown(() => debugDisableShadows = true);

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          _dummy = context;
          return const SizedBox();
        },
      ),
    );
    final harness = _Harness();
    await tester.pumpWidget(harness.app(route, arguments: arguments));
    await tester.runAsync(() async {
      final context = harness.navigatorKey.currentContext!;
      await precacheImage(const AssetImage('assets/images/e1.png'), context);
    });
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('auth', (tester) async {
    await start(tester, '/login');
    await shot(tester, '01_login');
    await tapText(tester, 'Daftar');
    await shot(tester, '02_register');
  });

  testWidgets('home, riwayat, profil', (tester) async {
    await start(tester, '/home');
    await shot(tester, '03_home');
    await tapText(tester, 'Riwayat');
    await shot(tester, '04_history');
    await tapText(tester, 'Profil');
    await shot(tester, '05_profile');
    await tapText(tester, 'Edit Profil');
    await shot(tester, '06_edit_profile');
  });

  testWidgets('home kosong', (tester) async {
    tester.view.physicalSize = _phone * _dpr;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);
    addTearDown(() => debugDisableShadows = true);
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          _dummy = context;
          return const SizedBox();
        },
      ),
    );
    final harness = _Harness()..consultations.history = [];
    await tester.pumpWidget(harness.app('/home'));
    await tester.pumpAndSettle();
    await shot(tester, '07_home_empty');
  });

  testWidgets('alur pemeriksaan', (tester) async {
    final h = await start(tester, '/home');
    await tapText(tester, 'Mulai Pemeriksaan');
    await shot(tester, '10_intro');
    await tapText(tester, 'Mulai Pemeriksaan');
    await shot(tester, '11_sq1');

    await tapText(tester, 'Ya'); // SQ1 -> otomatis lanjut ke SQ2
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await shot(tester, '12_sq2');
    await tapText(tester, '1 minggu atau lebih');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapText(tester, 'Ya, menetap atau kambuh-kambuhan');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await shot(tester, '13_sq4_long');

    // Jawab sisa pertanyaan gejala lewat provider agar cepat.
    while (h.diagnosis.stage == DiagnosisStage.sq) {
      final q = h.diagnosis.currentQuestion!;
      h.diagnosis.answerQuestion(q.code, q.input.options!.first.toString());
      h.diagnosis.nextQuestion();
    }
    await tester.pumpAndSettle();
    await shot(tester, '14_e1_empty');

    await tapText(tester, 'Lanjut'); // memunculkan validasi
    h.diagnosis.setAreaScore('E1', 'Temporalis', 1);
    await tester.pumpAndSettle();
    await tapText(tester, 'Lanjut');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await shot(tester, '15_e1_validation');

    h.diagnosis
      ..setAreaScore('E1', 'Masseter', 2)
      ..setAreaScore('E1', 'TMJ', 3);
    await tester.pumpAndSettle();
    await shot(tester, '16_e1_filled');
    await tapText(tester, 'Lanjut');
    await shot(tester, '17_e2');
    await tester.enterText(find.byType(TextField), '38');
    await tester.pumpAndSettle();
    await tapText(tester, 'Lanjut');
    await tapText(tester, 'Bunyi kliking');
    await shot(tester, '18_e3');
    await tapText(tester, 'Lanjut');
    for (final area in const ['Temporalis', 'Masseter', 'TMJ']) {
      h.diagnosis.setAreaScore('E4', area, 0);
    }
    await tester.pumpAndSettle();
    await tapText(tester, 'Selesai');
    await shot(tester, '19_confirm');
    await tapText(tester, 'Kirim & Lihat Hasil');
    await tester.pumpAndSettle();
    await shot(tester, '20_result');
  });

  testWidgets('hasil tanpa temuan', (tester) async {
    await start(
      tester,
      '/diagnosis_result',
      arguments: Consultation(
        id: 2,
        date: DateTime(2026, 11, 2, 19, 5),
        diagnoses: const ['No specific TMD diagnosis found.'],
      ),
    );
    await shot(tester, '21_result_clear');
  });
}
