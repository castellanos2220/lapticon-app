import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/api.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Errores legibles
// ---------------------------------------------------------------------------

String errorText(Object e) {
  if (e is ApiException) return e.message;
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return e.message ?? 'No se pudo completar la autenticación.';
    }
  }
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta acción (o ya se hizo antes).';
      case 'unavailable':
        return 'Sin conexión con la base de datos. Revisa tu internet.';
      case 'failed-precondition':
        return 'La base de datos rechazó la consulta. Actualiza la app e inténtalo de nuevo.';
      case 'not-found':
        return 'No se encontró el elemento.';
      default:
        return e.message ?? 'Error de base de datos (${e.code}).';
    }
  }
  if (e is StateError) return e.message;
  return 'Ocurrió un error inesperado.';
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(errorText(e)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.danger,
    ));
}

void showOk(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.navy));
}

Future<bool> confirmar(BuildContext context, {required String titulo, required String mensaje, String ok = 'Confirmar', bool peligro = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(
          style: peligro ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ---------------------------------------------------------------------------
// Superficies y textos
// ---------------------------------------------------------------------------

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = AppColors.line,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: Color(0x140B1D39), blurRadius: 24, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x080B1D39), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: borderColor)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 12),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.royal, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: AppColors.navy),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusChip(this.label, {super.key, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

Color colorEstadoEncargo(String estado) {
  switch (estado) {
    case 'publicado':
      return const Color(0xFF0284C7);
    case 'asignado':
      return AppColors.success;
    case 'entregado':
      return AppColors.navyLight;
    default:
      return AppColors.muted;
  }
}

class EncargoStatusChip extends StatelessWidget {
  final String estado;
  const EncargoStatusChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final icon = switch (estado) {
      'publicado' => Icons.search,
      'asignado' => Icons.handshake_outlined,
      'entregado' => Icons.check_circle_outline,
      _ => Icons.block,
    };
    final color = colorEstadoEncargo(estado);
    return StatusChip(estadosEncargo[estado] ?? estado, color: color, icon: icon);
  }
}

/// Pequeña píldora informativa (icono + texto).
class Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const Pill(this.icon, this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// "Bogota ✈ Madrid"
class RouteLine extends StatelessWidget {
  final String origen;
  final String destino;
  final double size;
  final Color color;
  const RouteLine(this.origen, this.destino, {super.key, this.size = 17, this.color = AppColors.navy});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color);
    return Semantics(
      label: 'De $origen a $destino',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Flexible(child: Text(origen, style: style, overflow: TextOverflow.ellipsis)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.flight_takeoff_rounded, size: size + 2, color: AppColors.sky),
            ),
            Flexible(child: Text(destino, style: style, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class FlightCodeChip extends StatelessWidget {
  final String code;
  final bool large;
  const FlightCodeChip(this.code, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 9, vertical: large ? 7 : 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_rounded, size: large ? 18 : 14, color: AppColors.sky),
          const SizedBox(width: 5),
          Text(
            code.isEmpty ? '—' : code,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: large ? 16 : 13, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const Avatar(this.name, {super.key, this.size = 44, this.color = AppColors.sky});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.12)],
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(iniciales(name), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: size * 0.36)),
    );
  }
}

/// Monto destacado.
class PriceTag extends StatelessWidget {
  final double precio;
  final String moneda;
  final String? caption;
  final bool large;
  const PriceTag(this.precio, this.moneda, {super.key, this.caption, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null) Text(caption!, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
        Text(dinero(precio, moneda), style: TextStyle(fontSize: large ? 26 : 18, fontWeight: FontWeight.w900, color: AppColors.success)),
      ],
    );
  }
}

class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Widget? action;
  const InfoBanner({super.key, required this.icon, required this.text, this.color = AppColors.sky, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color == AppColors.sky ? AppColors.navyLight : color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.35, color: AppColors.navy))),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: AppColors.royal.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Icon(icon, size: 38, color: AppColors.sky),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'No pudimos cargar esto',
      message: errorText(error),
      action: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
    );
  }
}

/// Indicador de carga que, si tarda, explica que el servidor puede estar despertando.
class LoadingView extends StatefulWidget {
  final String message;
  const LoadingView({super.key, this.message = 'Cargando…'});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  Timer? _t;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.navy),
            const SizedBox(height: 16),
            Text(widget.message, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _slow
                  ? const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'El servidor se está despertando; la primera vez puede tardar hasta un minuto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Capa de "procesando" sobre una pantalla mientras se guarda algo.
class BusyOverlay extends StatelessWidget {
  final bool busy;
  final Widget child;
  final String message;
  const BusyOverlay({super.key, required this.busy, required this.child, this.message = 'Guardando…'});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (busy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.75),
              child: LoadingView(message: message),
            ),
          ),
      ],
    );
  }
}

/// Botón principal a lo ancho con estado de carga.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final Color? color;
  const PrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.busy = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppColors.navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Icono asociado a cada tamaño de paquete.
IconData iconoTamano(Tamano t) => switch (t) {
      Tamano.pequeno => Icons.mail_outline_rounded,
      Tamano.mediano => Icons.inventory_2_outlined,
      Tamano.grande => Icons.luggage_outlined,
    };

IconData iconoCategoria(String c) => switch (c) {
      'documentos' => Icons.description_outlined,
      'ropa' => Icons.checkroom_outlined,
      'electronicos' => Icons.devices_other_outlined,
      'cosmeticos' => Icons.spa_outlined,
      'libros' => Icons.menu_book_outlined,
      'regalos' => Icons.card_giftcard_outlined,
      _ => Icons.category_outlined,
    };
