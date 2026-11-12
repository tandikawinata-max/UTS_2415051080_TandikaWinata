import 'package:flutter/material.dart';

/// Panduan posisi statis, bukan landmark hasil deteksi pose.
class BodyPositionGuide extends StatelessWidget {
  const BodyPositionGuide({super.key});
  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _GuidePainter()));
}

class _GuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF99C0D1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    canvas.drawCircle(p(.5, .14), size.width * .065, paint);
    final silhouette = Path()
      ..moveTo(size.width * .46, size.height * .21)
      ..lineTo(size.width * .36, size.height * .25)
      ..lineTo(size.width * .23, size.height * .51)
      ..moveTo(size.width * .54, size.height * .21)
      ..lineTo(size.width * .64, size.height * .25)
      ..lineTo(size.width * .77, size.height * .51)
      ..moveTo(size.width * .36, size.height * .25)
      ..lineTo(size.width * .40, size.height * .53)
      ..lineTo(size.width * .37, size.height * .88)
      ..moveTo(size.width * .64, size.height * .25)
      ..lineTo(size.width * .60, size.height * .53)
      ..lineTo(size.width * .63, size.height * .88)
      ..moveTo(size.width * .40, size.height * .53)
      ..lineTo(size.width * .60, size.height * .53);
    canvas.drawPath(silhouette, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
