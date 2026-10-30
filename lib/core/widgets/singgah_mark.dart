import 'package:flutter/material.dart';

import 'package:singgah/core/theme/app_theme.dart';

/// The pin + check mark used on the splash, auth, and lock screens.
class SinggahMark extends StatelessWidget {
  const SinggahMark({super.key, this.size = 44, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.singgah;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.navy,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.28),
                  blurRadius: size * 0.45,
                  offset: Offset(0, size * 0.16),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _PinCheckPainter(pin: colors.accent, check: colors.background),
      ),
    );
  }
}

class _PinCheckPainter extends CustomPainter {
  _PinCheckPainter({required this.pin, required this.check});

  final Color pin;
  final Color check;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pinPaint = Paint()..color = pin;
    final path = Path();
    final center = Offset(w * 0.5, h * 0.4);
    final radius = w * 0.22;
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.moveTo(w * 0.34, h * 0.56);
    path.quadraticBezierTo(w * 0.5, h * 0.82, w * 0.66, h * 0.56);
    path.close();
    canvas.drawPath(path, pinPaint);

    final checkPaint = Paint()
      ..color = check
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(w * 0.41, h * 0.40)
      ..lineTo(w * 0.48, h * 0.47)
      ..lineTo(w * 0.60, h * 0.33);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _PinCheckPainter oldDelegate) =>
      oldDelegate.pin != pin || oldDelegate.check != check;
}
