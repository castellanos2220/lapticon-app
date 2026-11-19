import 'package:flutter/material.dart';

import '../theme.dart';
import 'auth_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, Color(0xFF12294D)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LapticonLogo(light: true),
                const Spacer(),
                const _HeroIllustration(),
                const SizedBox(height: 32),
                const Text(
                  'Envía con viajeros\nque ya van para allá.',
                  style: TextStyle(color: Colors.white, fontSize: 32, height: 1.12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  'Publica tu encargo y el precio que pagas. Solo lo ven viajeros con un vuelo en tu ruta y a tiempo. Cuando hagan match, conversan por chat.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 15, height: 1.45),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ),
              ],
            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LapticonLogo extends StatelessWidget {
  final bool light;
  const LapticonLogo({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.navy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: light ? Colors.white : AppColors.navy, borderRadius: BorderRadius.circular(11)),
          child: Icon(Icons.flight_takeoff_rounded, color: light ? AppColors.navy : AppColors.sky, size: 22),
        ),
        const SizedBox(width: 10),
        Text('Lapticon', style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
      ],
    );
  }
}

/// Ilustración: ruta punteada con un avión llevando una caja.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        painter: _RoutePainter(),
        child: Stack(
          children: [
            const Positioned(left: 0, bottom: 4, child: _CityDot(label: 'BOG')),
            const Positioned(right: 0, top: 4, child: _CityDot(label: 'MAD')),
            Align(
              alignment: const Alignment(0.05, -0.15),
              child: Transform.rotate(
                angle: -0.35,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flight_rounded, color: Colors.white, size: 46),
                    Container(
                      width: 18,
                      height: 16,
                      decoration: BoxDecoration(color: AppColors.kraft, borderRadius: BorderRadius.circular(3)),
                      child: Center(child: Container(width: 18, height: 3, color: AppColors.sky)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityDot extends StatelessWidget {
  final String label;
  const _CityDot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontFamily: 'monospace')),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(30, size.height - 20)
      ..quadraticBezierTo(size.width * 0.45, -size.height * 0.25, size.width - 30, 24);
    final paint = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
