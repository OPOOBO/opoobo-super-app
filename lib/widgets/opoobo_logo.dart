import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OpooboLogo extends StatelessWidget {
  final double size;

  const OpooboLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 34,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoPainter(), size: Size(size, size)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 48;

    // Outer circle (ring)
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, 15 * scale, ringPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5.5 * scale, dotPaint);

    // Cross-hair lines
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round;

    // Top line
    canvas.drawLine(
      Offset(center.dx, center.dy - 8 * scale),
      Offset(center.dx, center.dy - 22 * scale),
      linePaint,
    );
    // Bottom line
    canvas.drawLine(
      Offset(center.dx, center.dy + 8 * scale),
      Offset(center.dx, center.dy + 22 * scale),
      linePaint,
    );
    // Left line
    canvas.drawLine(
      Offset(center.dx - 8 * scale, center.dy),
      Offset(center.dx - 22 * scale, center.dy),
      linePaint,
    );
    // Right line
    canvas.drawLine(
      Offset(center.dx + 8 * scale, center.dy),
      Offset(center.dx + 22 * scale, center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
