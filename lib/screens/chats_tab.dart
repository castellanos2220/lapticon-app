import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/matches_controller.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'encargo_detail_screen.dart';

/// Conversaciones activas (match) y solicitudes en espera.
class ChatsTab extends StatelessWidget {
  final VoidCallback onIrAEnvios;
  final VoidCallback onIrAViajar;
  const ChatsTab({super.key, required this.onIrAEnvios, required this.onIrAViajar});

  @override
  Widget build(BuildContext context) {
    final ctrl = MatchesController.instance;
    return Scaffold(
      appBar: lapAppBar('Chats'),
      body: ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) {
          if (ctrl.error != null && ctrl.items.isEmpty) {
            return ErrorView(error: ctrl.error!, onRetry: ctrl.retry);
          }
          if (ctrl.loading) return const LoadingView(message: 'Cargando chats…');
          final uid = LapticonStore.instance.uid;
          final chats = ctrl.items.where((m) => m.esMatch).toList();
          final porResponder = ctrl.items.where((m) => m.pendiente && m.senderId == uid).toList();
          final esperando = ctrl.items.where((m) => m.pendiente && m.travelerId == uid).toList();

          if (chats.isEmpty && porResponder.isEmpty && esperando.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Aún no tienes chats',
                  message: 'El chat se abre cuando un remitente y un viajero hacen match. Publica un envío o registra tu vuelo para empezar.',
                  action: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(onPressed: onIrAEnvios, icon: const Icon(Icons.inventory_2_outlined), label: const Text('Enviar algo')),
                      OutlinedButton.icon(onPressed: onIrAViajar, icon: const Icon(Icons.flight_takeoff), label: const Text('Tengo un vuelo')),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              if (porResponder.isNotEmpty) ...[
                const SectionTitle('Viajeros esperando tu respuesta'),
                for (final m in porResponder) ...[
                  _PendienteTile(
                    match: m,
                    texto: '${m.travelerName} quiere llevar tu encargo',
                    accion: 'Revisar',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EncargoDetailScreen(encargoId: m.encargoId))),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              if (chats.isNotEmpty) ...[
                const SectionTitle('Conversaciones'),
                for (final m in chats) ...[_ChatTile(match: m, uid: uid), const SizedBox(height: 8)],
              ],
              if (esperando.isNotEmpty) ...[
                const SectionTitle('Esperando respuesta del remitente'),
                for (final m in esperando) ...[
                  _PendienteTile(
                    match: m,
                    texto: 'Pediste llevar el encargo de ${m.senderName}',
                    accion: null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: m.id))),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final MatchDoc match;
  final String uid;
  const _ChatTile({required this.match, required this.uid});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final unread = m.noLeidoPara(uid);
    final otro = m.otroNombre(uid);
    final preview = m.lastMessage == null
        ? '¡Hicieron match! Escribe el primer mensaje.'
        : '${m.lastSenderId == uid ? 'Tú: ' : ''}${m.lastMessage}';
    final when = m.lastMessageAt ?? m.updatedAt;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: unread ? AppColors.sky : AppColors.line,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: m.id))),
      child: Row(
        children: [
          Avatar(otro, size: 48, color: unread ? AppColors.sky : AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(otro, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
                    ),
                    if (when != null)
                      Text(horaOFecha(when), style: TextStyle(fontSize: 12, color: unread ? AppColors.navy : AppColors.muted, fontWeight: unread ? FontWeight.w800 : FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.numeroVuelo} · ${m.ciudadOrigen} → ${m.ciudadDestino}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: unread ? AppColors.navy : AppColors.muted, fontWeight: unread ? FontWeight.w700 : FontWeight.w400),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(color: AppColors.sky, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendienteTile extends StatelessWidget {
  final MatchDoc match;
  final String texto;
  final String? accion;
  final VoidCallback onTap;
  const _PendienteTile({required this.match, required this.texto, required this.accion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = match;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.schedule_rounded, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(
                  '${m.numeroVuelo} · ${m.ciudadOrigen} → ${m.ciudadDestino}${m.fechaViaje != null ? ' · ${fechaCorta(m.fechaViaje!)}' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (accion != null) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(onPressed: onTap, child: Text(accion!)),
          ] else
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
