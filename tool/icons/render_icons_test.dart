// Membuat ikon aplikasi (PNG) dari lambang gigi yang sama dengan AppLogo.
//
//   flutter test tool/icons/render_icons_test.dart
//
// Hasil di `tool/icons/out/`; salin ke folder platform dengan
// `tool/icons/install_icons.sh`.
import 'package:dentistapp/core/theme/app_colors.dart';
import 'package:dentistapp/core/widgets/app_logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Ikon persegi penuh (tanpa sudut membulat & tanpa transparansi): iOS dan
/// toko aplikasi memotong sudutnya sendiri.
class _SquareIcon extends StatelessWidget {
  final double size;
  final bool rounded;

  const _SquareIcon({required this.size, this.rounded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBE6F80), AppColors.primaryDark],
        ),
        borderRadius: rounded ? BorderRadius.circular(size * 0.22) : null,
      ),
      padding: EdgeInsets.all(size * 0.2),
      child: const CustomPaint(painter: ToothPainter(color: Colors.white)),
    );
  }
}

void main() {
  setUpAll(() => autoUpdateGoldenFiles = true);

  Future<void> render(
    WidgetTester tester,
    String name,
    double size, {
    bool rounded = false,
  }) async {
    tester.view.physicalSize = Size(size, size);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: _SquareIcon(size: size, rounded: rounded),
        ),
      ),
    );
    await expectLater(find.byKey(key), matchesGoldenFile('out/$name.png'));
  }

  testWidgets('ikon persegi 1024', (tester) async {
    await render(tester, 'icon_square_1024', 1024);
  });

  testWidgets('ikon membulat 512 (Android lama)', (tester) async {
    await render(tester, 'icon_rounded_512', 512, rounded: true);
  });
}
