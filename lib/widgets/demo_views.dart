import 'package:flutter/material.dart';

import '../demo.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';
import 'immersive.dart';

/// Detalle de un encargo de ejemplo. No escribe nada en el servidor.
Future<void> showDemoEncargo(
  BuildContext context,
  Encargo e, {
  required bool comoViajero,
  String? accionLabel,
  VoidCallback? onAccion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const DemoBadge(),
                const SizedBox(width: 8),
                EncargoStatusChip(e.estado),
                const Spacer(),
                PriceTag(e.precio, e.moneda, caption: comoViajero ? 'Te pagan' : 'Pagas', large: true),
              ],
            ),
            const SizedBox(height: 18),
            RouteCodes(e.ciudadOrigen, e.ciudadDestino, codeSize: 28),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: AppColors.kraftSoft, borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconoCategoria(e.categoria), color: AppColors.kraftDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.categoriaLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(e.descripcion, style: const TextStyle(color: AppColors.muted, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Pill(Icons.event_outlined, 'Límite ${fechaCorta(e.fechaLimite)}'),
                Pill(iconoTamano(e.tamano), '${e.tamano.label} · ${kg(e.pesoKg)}'),
                if (comoViajero) Pill(Icons.person_outline_rounded, e.senderName),
                if (!comoViajero && demoInteresados(e.id) > 0)
                  Pill(Icons.person_search_rounded, '${demoInteresados(e.id)} viajeros interesados', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 18),
            const DemoSectionNote(
              'Este es un ejemplo para que veas cómo funciona Lapticon. Los encargos reales aparecen aquí en cuanto se publican.',
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: accionLabel ?? 'Entendido',
              icon: accionLabel == null ? Icons.check_rounded : Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.pop(c);
                onAccion?.call();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Conversación de ejemplo, solo lectura.
class DemoChatScreen extends StatelessWidget {
  final DemoChat chat;
  const DemoChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: lapAppBar(
        '',
        titleWidget: Row(
          children: [
            Avatar(chat.nombre, size: 38, color: AppColors.sky),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${chat.rol} · ${chat.vuelo}', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
                ],
              ),
            ),
            const DemoBadge(dark: true),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
            child: Row(
              children: [
                Expanded(child: RouteCodes(chat.origen, chat.destino, codeSize: 18)),
                const SizedBox(width: 12),
                PriceTag(chat.precio, 'USD'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                for (final m in chat.mensajes) _Bubble(m),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chat de ejemplo. Tus chats reales se abren cuando haces match.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final DemoMensaje m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) {
    final mio = m.mio;
    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          gradient: mio ? const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]) : null,
          color: mio ? null : Colors.white,
          border: mio ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mio ? 18 : 4),
            bottomRight: Radius.circular(mio ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(m.texto, style: TextStyle(color: mio ? Colors.white : AppColors.navy, height: 1.35)),
            const SizedBox(height: 3),
            Text(m.hora, style: TextStyle(fontSize: 10.5, color: mio ? Colors.white60 : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
