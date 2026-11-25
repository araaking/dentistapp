import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Lambang Dentist App: siluet gigi di dalam kotak membulat.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 72});

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
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: const CustomPaint(painter: ToothPainter(color: Colors.white)),
      ),
    );
  }
}

/// Menggambar siluet gigi geraham pada kanvas 24x24 yang diskalakan.
class ToothPainter extends CustomPainter {
  final Color color;

  const ToothPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.translate(
      (size.width - 24 * scale) / 2,
      (size.height - 24 * scale) / 2,
    );
    canvas.scale(scale);

    final path = Path()
      ..moveTo(12, 5.2)
      ..cubicTo(10.6, 4.2, 9.2, 3.5, 7.6, 3.5)
      ..cubicTo(5, 3.5, 3.5, 5.6, 3.5, 8.2)
      ..cubicTo(3.5, 10.4, 4.3, 11.9, 4.9, 13.6)
      ..cubicTo(5.5, 15.4, 5.6, 17.6, 6.2, 19.3)
      ..cubicTo(6.5, 20.2, 7, 20.9, 7.8, 20.9)
      ..cubicTo(8.7, 20.9, 9.1, 20, 9.3, 19)
      ..cubicTo(9.6, 17.4, 9.8, 15.4, 10.6, 14.4)
      ..cubicTo(11, 13.9, 11.5, 13.7, 12, 13.7)
      ..cubicTo(12.5, 13.7, 13, 13.9, 13.4, 14.4)
      ..cubicTo(14.2, 15.4, 14.4, 17.4, 14.7, 19)
      ..cubicTo(14.9, 20, 15.3, 20.9, 16.2, 20.9)
      ..cubicTo(17, 20.9, 17.5, 20.2, 17.8, 19.3)
      ..cubicTo(18.4, 17.6, 18.5, 15.4, 19.1, 13.6)
      ..cubicTo(19.7, 11.9, 20.5, 10.4, 20.5, 8.2)
      ..cubicTo(20.5, 5.6, 19, 3.5, 16.4, 3.5)
      ..cubicTo(14.8, 3.5, 13.4, 4.2, 12, 5.2)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(ToothPainter oldDelegate) => oldDelegate.color != color;
}
