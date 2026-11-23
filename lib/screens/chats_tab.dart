import 'package:flutter/material.dart';

import '../demo.dart';
import '../format.dart';
import '../models.dart';
import '../services/matches_controller.dart';
import '../services/role.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/demo_views.dart';
import '../widgets/immersive.dart';
import 'chat_screen.dart';
import 'encargo_detail_screen.dart';

/// Conversaciones activas (match) y solicitudes en espera.
class ChatsTab extends StatelessWidget {
  final AppRole role;
  final VoidCallback onIrAInicio;
  const ChatsTab({super.key, required this.role, required this.onIrAInicio});

  @override
  Widget build(BuildContext context) {
    final ctrl = MatchesController.instance;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final uid = LapticonStore.instance.uid;
        final chats = ctrl.items.where((m) => m.esMatch).toList();
        final porResponder = ctrl.items.where((m) => m.pendiente && m.senderId == uid).toList();
        final esperando = ctrl.items.where((m) => m.pendiente && m.travelerId == uid).toList();
        final unread = ctrl.noLeidos(uid);
        final vacio = !ctrl.loading && chats.isEmpty && porResponder.isEmpty && esperando.isEmpty;

        return ImmersivePage(
          onRefresh: () async => ctrl.retry(),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          header: HeroHeader(
            eyebrow: 'Mensajes',
            title: 'Chats',
            subtitle: unread > 0
                ? 'Tienes $unread ${unread == 1 ? 'conversación' : 'conversaciones'} con mensajes nuevos.'
                : 'Coordina la entrega con quien hiciste match.',
            seed: 4,
            child: HeroStats([
              ('${chats.length}', 'Conversaciones'),
              ('${porResponder.length + esperando.length}', 'Solicitudes'),
              ('$unread', 'Sin leer'),
            ]),
          ),
          children: [
            if (ctrl.error != null && ctrl.items.isEmpty)
              ErrorView(error: ctrl.error!, onRetry: ctrl.retry)
            else if (ctrl.loading)
              const Padding(padding: EdgeInsets.only(top: 40), child: LoadingView(message: 'Cargando chats…'))
            else if (vacio) ...[
              const DemoSectionNote('Aún no tienes chats. El chat se abre cuando un remitente y un viajero hacen match. Así se ven:'),
              const SectionTitle('Conversaciones'),
              for (final c in demoChats) ...[_DemoChatTile(chat: c), const SizedBox(height: 10)],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onIrAInicio,
                icon: Icon(role == AppRole.remitente ? Icons.inventory_2_outlined : Icons.flight_takeoff),
                label: Text(role == AppRole.remitente ? 'Publicar un envío' : 'Buscar encargos para mi vuelo'),
              ),
            ] else ...[
              if (porResponder.isNotEmpty) ...[
                const SectionTitle('Viajeros esperando tu respuesta'),
                for (final m in porResponder) ...[
                  _PendienteTile(
                    match: m,
                    texto: '${m.travelerName} quiere llevar tu encargo',
                    accion: 'Revisar',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EncargoDetailScreen(encargoId: m.encargoId))),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (chats.isNotEmpty) ...[
                const SectionTitle('Conversaciones'),
                for (final m in chats) ...[_ChatTile(match: m, uid: uid), const SizedBox(height: 10)],
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
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ],
        );
      },
    );
  }
}

class _DemoChatTile extends StatelessWidget {
  final DemoChat chat;
  const _DemoChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final c = chat;
    final last = c.mensajes.last;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: c.noLeido ? AppColors.sky : AppColors.line,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DemoChatScreen(chat: c))),
      child: Row(
        children: [
          Avatar(c.nombre, size: 50, color: c.noLeido ? AppColors.sky : AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(c.nombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    const SizedBox(width: 6),
                    const DemoBadge(),
                    const Spacer(),
                    Text(last.hora, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${c.vuelo} · ${c.origen} → ${c.destino}', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${last.mio ? 'Tú: ' : ''}${last.texto}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.noLeido ? AppColors.navy : AppColors.muted, fontWeight: c.noLeido ? FontWeight.w700 : FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
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
