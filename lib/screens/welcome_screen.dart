import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/immersive.dart';
import 'auth_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SkyBackdrop(
          seed: 5,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LapticonLogo(light: true),
                          const Spacer(),
                          const _AnimatedRoute(),
                          const SizedBox(height: 28),
                          const Text(
                            'Envía con viajeros\nque ya van para allá.',
                            style: TextStyle(color: Colors.white, fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Publica tu encargo o registra tu vuelo. Te conectamos solo con personas en tu misma ruta y a tiempo.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15.5, height: 1.45),
                          ),
                          const SizedBox(height: 20),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Feature(Icons.verified_user_outlined, 'Match verificado'),
                              _Feature(Icons.chat_bubble_outline_rounded, 'Chat en tiempo real'),
                              _Feature(Icons.route_outlined, 'Misma ruta'),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.navy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text('Crear cuenta'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.sky),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.royal, AppColors.sky], begin: Alignment.bottomLeft, end: Alignment.topRight),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.royal.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Text('Lapticon', style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
      ],
    );
  }
}

/// Ruta BOG → MAD con un avión que la recorre en bucle.
class _AnimatedRoute extends StatefulWidget {
  const _AnimatedRoute();

  @override
  State<_AnimatedRoute> createState() => _AnimatedRouteState();
}

class _AnimatedRouteState extends State<_AnimatedRoute> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(painter: _RoutePainter(Curves.easeInOut.transform(_c.value))),
            ),
          ),
          const Positioned(left: 0, bottom: 0, child: _CityTag(code: 'BOG', city: 'Bogotá')),
          const Positioned(right: 0, top: 0, child: _CityTag(code: 'MAD', city: 'Madrid', alignEnd: true)),
        ],
      ),
    );
  }
}

class _CityTag extends StatelessWidget {
  final String code;
  final String city;
  final bool alignEnd;
  const _CityTag({required this.code, required this.city, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 17)),
          Text(city, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double t;
  _RoutePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(36, size.height - 52);
    final end = Offset(size.width - 36, 52);
    final ctrl = Offset(size.width * 0.42, -size.height * 0.15);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    final metric = path.computeMetrics().first;
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, d + 6), dash);
      d += 13;
    }

    // Estela recorrida
    final traveled = metric.extractPath(0, metric.length * t);
    canvas.drawPath(
      traveled,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0x005FB3FF), AppColors.sky]).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Puntos de ciudad
    for (final p in [start, end]) {
      canvas.drawCircle(p, 9, Paint()..color = AppColors.sky.withValues(alpha: 0.2));
      canvas.drawCircle(p, 4.5, Paint()..color = AppColors.sky);
    }

    // Avión
    final tan = metric.getTangentForOffset(metric.length * t);
    if (tan != null) {
      canvas.drawCircle(tan.position, 22, Paint()..color = AppColors.royal.withValues(alpha: 0.25));
      canvas.save();
      canvas.translate(tan.position.dx, tan.position.dy);
      canvas.rotate(-tan.angle + math.pi / 2);
      final icon = Icons.flight_rounded;
      final tp = TextPainter(
        text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: 30, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.t != t;
}
