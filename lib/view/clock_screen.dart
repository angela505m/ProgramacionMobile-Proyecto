import 'package:flutter/material.dart';
import 'dart:math';

class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reloj de Paseo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: ClipOval(
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Reloj analógico
                  const CustomPaint(
                    size: Size(250, 250),
                    painter: VisibleClockPainter(),
                  ),
                  // Texto digital central (opcional)
                  const Text(
                    '10:10',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  // Botón en la parte INFERIOR (dentro del círculo)
                  Positioned(
                    bottom: 16, // separación del borde inferior
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Iniciando paseo...'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF96C9F2),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      child: const Text('INICIAR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pintor con trazos gruesos (reloj estático)
class VisibleClockPainter extends CustomPainter {
  const VisibleClockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final markPaint = Paint()
      ..color = const Color(0xFF96C9F2)
      ..strokeWidth = 3;
    final hourHandPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    final minuteHandPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    final secondHandPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, facePaint);

    // Marcas de horas
    for (int i = 1; i <= 12; i++) {
      double angle = (i * 30) * pi / 180;
      double innerRadius = radius - 10;
      double outerRadius = radius - 25;
      Offset start = Offset(
        center.dx + innerRadius * cos(angle - pi / 2),
        center.dy + innerRadius * sin(angle - pi / 2),
      );
      Offset end = Offset(
        center.dx + outerRadius * cos(angle - pi / 2),
        center.dy + outerRadius * sin(angle - pi / 2),
      );
      canvas.drawLine(start, end, markPaint);
    }

    // Manecilla hora (10)
    double hourAngle = (10 * 30 + 10 * 0.5) * pi / 180;
    Offset hourHand = Offset(
      center.dx + (radius * 0.45) * cos(hourAngle - pi / 2),
      center.dy + (radius * 0.45) * sin(hourAngle - pi / 2),
    );
    canvas.drawLine(center, hourHand, hourHandPaint);

    // Manecilla minuto (10)
    double minuteAngle = (10 * 6) * pi / 180;
    Offset minuteHand = Offset(
      center.dx + (radius * 0.65) * cos(minuteAngle - pi / 2),
      center.dy + (radius * 0.65) * sin(minuteAngle - pi / 2),
    );
    canvas.drawLine(center, minuteHand, minuteHandPaint);

    // Segundero (35)
    double secondAngle = (35 * 6) * pi / 180;
    Offset secondHand = Offset(
      center.dx + (radius * 0.75) * cos(secondAngle - pi / 2),
      center.dy + (radius * 0.75) * sin(secondAngle - pi / 2),
    );
    canvas.drawLine(center, secondHand, secondHandPaint);

    // Centro
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF96C9F2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
