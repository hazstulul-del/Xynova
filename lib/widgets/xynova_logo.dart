import 'package:flutter/material.dart';

class XynovaLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const XynovaLogo({
    super.key,
    this.size = 28,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: _LogoPainter(textColor),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 9),
          Text(
            'Xynova',
            style: TextStyle(
              fontSize: size * .62,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: textColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .12
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * .34;
    canvas.drawLine(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), p);
    canvas.drawLine(Offset(c.dx + r, c.dy - r), Offset(c.dx - r, c.dy + r), p);
    canvas.drawCircle(c, size.width * .46, p);
    canvas.drawCircle(Offset(c.dx + r * .9, c.dy - r * .9), size.width * .055, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.color != color;
}
