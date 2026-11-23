import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Códigos de aeropuerto para mostrar rutas tipo pase de abordar
// ---------------------------------------------------------------------------

const _codigos = <String, String>{
  'bogota': 'BOG',
  'medellin': 'MDE',
  'cali': 'CLO',
  'cartagena': 'CTG',
  'barranquilla': 'BAQ',
  'bucaramanga': 'BGA',
  'pereira': 'PEI',
  'santa marta': 'SMR',
  'cucuta': 'CUC',
  'miami': 'MIA',
  'madrid': 'MAD',
  'paris': 'CDG',
  'barcelona': 'BCN',
  'nueva york': 'JFK',
  'new york': 'JFK',
  'mexico': 'MEX',
  'ciudad de mexico': 'MEX',
  'lima': 'LIM',
  'santiago': 'SCL',
  'buenos aires': 'EZE',
  'londres': 'LHR',
  'london': 'LHR',
  'panama': 'PTY',
  'quito': 'UIO',
  'orlando': 'MCO',
};

String cityCode(String city) {
  final k = normalizeCity(city);
  final c = _codigos[k];
  if (c != null) return c;
  final letters = k.replaceAll(RegExp(r'[^a-z]'), '');
  if (letters.isEmpty) return '---';
  return letters.substring(0, math.min(3, letters.length)).toUpperCase();
}

// ---------------------------------------------------------------------------
// Fondo: cielo nocturno con rutas de vuelo punteadas y halos de luz
// ---------------------------------------------------------------------------

class SkyBackdrop extends StatelessWidget {
  final Widget child;
  final double seed;
  const SkyBackdrop({super.key, required this.child, this.seed = 1});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: heroGradient),
      child: CustomPaint(painter: _SkyPainter(seed), child: child),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double seed;
  _SkyPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    // Halos
    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    glow(Offset(size.width * 0.92, size.height * 0.05), size.width * 0.55, AppColors.royal.withValues(alpha: 0.32));
    glow(Offset(size.width * 0.05, size.height * 0.95), size.width * 0.45, AppColors.sky.withValues(alpha: 0.14));

    // Estrellas (pseudoaleatorias pero estables)
    final rnd = math.Random((seed * 1000).round());
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 38; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      star.color = Colors.white.withValues(alpha: 0.08 + rnd.nextDouble() * 0.22);
      canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.1, star);
    }

    // Meridianos del globo
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final globe = Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.15), radius: size.width * 0.55);
    for (var i = 1; i <= 4; i++) {
      canvas.drawOval(globe.deflate(globe.width * 0.11 * i).translate(0, 0), grid);
    }
    canvas.drawOval(Rect.fromCenter(center: globe.center, width: globe.width * 0.35, height: globe.height), grid);

    // Rutas punteadas
    final route = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final p1 = Path()
      ..moveTo(-20, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.05, size.width + 20, size.height * 0.35);
    final p2 = Path()
      ..moveTo(size.width * 0.1, -10)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.4, size.width + 10, size.height * 0.95);
    for (final path in [p1, p2]) {
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + 5), route);
          d += 12;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.seed != seed;
}

// ---------------------------------------------------------------------------
// Página con cabecera inmersiva y hoja de contenido superpuesta
// ---------------------------------------------------------------------------

class ImmersivePage extends StatelessWidget {
  final Widget header;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final EdgeInsets contentPadding;

  const ImmersivePage({
    super.key,
    required this.header,
    required this.children,
    this.onRefresh,
    this.floatingActionButton,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 22, 16, 110),
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.zero,
      children: [
        header,
        Container(
          transform: Matrix4.translationValues(0, -28, 0),
          decoration: const BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: contentPadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.mist,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            // Evita que se vea el fondo claro al estirar hacia abajo.
            const Positioned(top: 0, left: 0, right: 0, height: 300, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.ink))),
            onRefresh == null
                ? list
                : RefreshIndicator(onRefresh: onRefresh!, color: AppColors.navy, edgeOffset: 0, child: list),
          ],
        ),
      ),
    );
  }
}

class HeroHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;
  final double seed;

  const HeroHeader({super.key, required this.eyebrow, required this.title, this.subtitle, this.trailing, this.child, this.seed = 1});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SkyBackdrop(
      seed: seed,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top + 18, 20, 54),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: TextStyle(color: AppColors.sky.withValues(alpha: 0.9), fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.8),
                      ),
                      const SizedBox(height: 8),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 14.5, height: 1.4)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            if (child != null) ...[const SizedBox(height: 22), child!],
          ],
        ),
      ),
    );
  }
}

/// Panel translúcido sobre fondo oscuro.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.13), Colors.white.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: child,
    );
  }
}

/// Fila de indicadores dentro de la cabecera.
class HeroStats extends StatelessWidget {
  final List<(String, String)> stats; // (valor, etiqueta)
  const HeroStats(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.12)),
            Expanded(
              child: Column(
                children: [
                  Text(stats[i].$1, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(stats[i].$2, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón circular translúcido para la cabecera.
class HeroIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const HeroIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      icon: Icon(icon),
    );
  }
}

/// "BOG ---✈--- MAD" con los nombres de ciudad debajo.
class RouteCodes extends StatelessWidget {
  final String origen;
  final String destino;
  final bool dark;
  final double codeSize;
  const RouteCodes(this.origen, this.destino, {super.key, this.dark = false, this.codeSize = 24});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.navy;
    final sub = dark ? Colors.white.withValues(alpha: 0.6) : AppColors.muted;
    Widget side(String city, bool end) => Column(
          crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(cityCode(city), style: TextStyle(color: fg, fontSize: codeSize, fontWeight: FontWeight.w800, letterSpacing: 0.5, height: 1.05)),
            const SizedBox(height: 2),
            Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        );
    return Semantics(
      label: 'De $origen a $destino',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(flex: 3, child: side(origen, false)),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(child: _Dashes(color: dark ? Colors.white24 : AppColors.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Transform.rotate(angle: math.pi / 2, child: Icon(Icons.flight_rounded, size: 20, color: dark ? AppColors.sky : AppColors.royal)),
                    ),
                    Expanded(child: _Dashes(color: dark ? Colors.white24 : AppColors.line)),
                  ],
                ),
              ),
            ),
            Expanded(flex: 3, child: side(destino, true)),
          ],
        ),
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  final Color color;
  const _Dashes({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 7).floor().clamp(1, 60);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(n, (_) => Container(width: 3.5, height: 1.6, color: color)),
        );
      },
    );
  }
}

/// Etiqueta de dato simulado.
class DemoBadge extends StatelessWidget {
  final bool dark;
  const DemoBadge({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.12) : AppColors.kraftSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dark ? Colors.white24 : AppColors.kraft.withValues(alpha: 0.5)),
      ),
      child: Text(
        'EJEMPLO',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: dark ? Colors.white70 : AppColors.kraftDeep),
      ),
    );
  }
}

/// Encabezado de sección para listas de ejemplo, con una nota explicativa.
class DemoSectionNote extends StatelessWidget {
  final String text;
  const DemoSectionNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kraftSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kraft.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.kraftDeep),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.kraftDeep, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
