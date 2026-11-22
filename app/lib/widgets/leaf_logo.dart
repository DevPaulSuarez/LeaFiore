// ═══ leaf_logo.dart · LOGO (dibujado con código, sin imagen) ═══

import 'package:flutter/material.dart';

/// Logo de LeaFiore: un brote con cuatro hojas (dibujado, sin imágenes).
class LeafLogo extends StatelessWidget {
  final double size;
  final Color color;
  const LeafLogo({super.key, this.size = 64, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _LogoPainter(color));
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(const Offset(32, 52), const Offset(32, 30), p);
    // hoja derecha superior
    canvas.drawPath(
      Path()
        ..moveTo(32, 30)
        ..cubicTo(32, 21, 37, 15, 37, 15)
        ..cubicTo(37, 15, 42, 21, 42, 28)
        ..cubicTo(42, 34, 38, 37, 32, 37),
      p,
    );
    // hoja izquierda superior
    canvas.drawPath(
      Path()
        ..moveTo(32, 30)
        ..cubicTo(32, 21, 27, 15, 27, 15)
        ..cubicTo(27, 15, 22, 21, 22, 28)
        ..cubicTo(22, 34, 26, 37, 32, 37),
      p,
    );
    // hojas laterales
    canvas.drawPath(
      Path()
        ..moveTo(32, 40)
        ..cubicTo(26, 40, 18, 38, 16, 31)
        ..cubicTo(22, 30, 28, 32, 32, 37),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(32, 40)
        ..cubicTo(38, 40, 46, 38, 48, 31)
        ..cubicTo(42, 30, 36, 32, 32, 37),
      p,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
