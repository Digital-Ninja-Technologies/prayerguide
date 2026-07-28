import 'package:flutter/material.dart';

/// The multicolor Google "G" mark, drawn to avoid bundling an image asset.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    void arc(double startDeg, double sweepDeg, Color color) {
      paint.color = color;
      canvas.drawArc(rect, startDeg * 3.1415926535 / 180, sweepDeg * 3.1415926535 / 180, false, paint);
    }

    arc(-40, -130, _red);
    arc(90, 90, _green);
    arc(180, 90, _yellow);
    arc(-40, 130, _blue);

    final barPaint = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - strokeWidth / 2, size.width / 2 - strokeWidth * 0.35, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
