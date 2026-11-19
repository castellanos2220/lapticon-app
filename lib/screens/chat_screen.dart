import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../services/matches_controller.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Chat entre remitente y viajero. Solo existe cuando hay match
/// (las reglas de Firestore también lo exigen en el servidor).
class ChatScreen extends StatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _store = LapticonStore.instance;
  final _text = TextEditingController();
  final _focus = FocusNode();
  late final Stream<List<Mensaje>> _mensajes = _store.mensajes(widget.matchId);
  DateTime? _ultimoMarcado;
  bool _enviando = false;

  static const _sugerencias = [
    '¡Hola! ¿Dónde nos vemos para la entrega?',
    '¿A qué hora te queda bien?',
    'Te comparto fotos del paquete.',
  ];

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _marcarLeido(MatchDoc m) {
    final uid = _store.uid;
    if (!m.noLeidoPara(uid) || m.lastMessageAt == _ultimoMarcado) return;
    _ultimoMarcado = m.lastMessageAt;
    _store.marcarLeido(m).ignore();
  }

  Future<void> _enviar(MatchDoc m, [String? texto]) async {
    final t = (texto ?? _text.text).trim();
    if (t.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    if (texto == null) _text.clear();
    try {
      await _store.enviarMensaje(m, t.length > 1000 ? t.substring(0, 1000) : t);
      HapticFeedback.selectionClick();
    } catch (e) {
      if (texto == null && _text.text.isEmpty) _text.text = t; // no perder lo escrito
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MatchesController.instance,
      builder: (context, _) {
        final m = MatchesController.instance.byId(widget.matchId);
        if (m == null) {
          return Scaffold(appBar: lapAppBar('Chat'), body: const LoadingView(message: 'Abriendo chat…'));
        }
        final uid = _store.uid;
        WidgetsBinding.instance.addPostFrameCallback((_) => _marcarLeido(m));
        final otro = m.otroNombre(uid);
        return Scaffold(
          backgroundColor: AppColors.mist,
          appBar: lapAppBar(
            otro,
            titleWidget: Row(
              children: [
                Avatar(otro, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otro, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.navy)),
                      Text(m.soyRemitente(uid) ? 'Lleva tu encargo' : 'Remitente', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              _TratoHeader(match: m, uid: uid),
              Expanded(
                child: m.esMatch
                    ? StreamBuilder<List<Mensaje>>(
                        stream: _mensajes,
                        builder: (context, snap) {
                          if (snap.hasError) return ErrorView(error: snap.error!, onRetry: () => setState(() {}));
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          final msgs = snap.data!;
                          if (msgs.isEmpty) return _ChatVacio(nombre: otro, onSugerencia: (s) => _enviar(m, s), sugerencias: _sugerencias);
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            itemCount: msgs.length,
                            itemBuilder: (context, i) {
                              final msg = msgs[i];
                              final mine = msg.senderId == uid;
                              final older = i + 1 < msgs.length ? msgs[i + 1] : null;
                              final date = msg.createdAt ?? DateTime.now();
                              final olderDate = older?.createdAt ?? date;
                              final newDay = older == null || !_mismoDia(date, olderDate);
                              final agrupado = older != null && older.senderId == msg.senderId && !newDay;
                              return Column(
                                children: [
                                  if (newDay) _DaySeparator(diaRelativo(date)),
                                  _Bubble(msg: msg, mine: mine, compacto: agrupado),
                                ],
                              );
                            },
                          );
                        },
                      )
                    : _ChatBloqueado(match: m, uid: uid),
              ),
              if (m.esMatch) _Composer(controller: _text, focus: _focus, enviando: _enviando, onSend: () => _enviar(m)),
            ],
          ),
        );
      },
    );
  }

  static bool _mismoDia(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }
}

/// Resumen fijo del trato: vuelo, ruta y pago acordado.
class _TratoHeader extends StatelessWidget {
  final MatchDoc match;
  final String uid;
  const _TratoHeader({required this.match, required this.uid});

  @override
  Widget build(BuildContext context) {
    final m = match;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          FlightCodeChip(m.numeroVuelo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.ciudadOrigen} → ${m.ciudadDestino}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text(
                  m.fechaViaje == null ? m.descripcion : '${fechaCorta(m.fechaViaje!)} · ${m.descripcion}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriceTag(m.precio, m.moneda, caption: m.soyRemitente(uid) ? 'Pagas' : 'Recibes'),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Mensaje msg;
  final bool mine;
  final bool compacto;
  const _Bubble({required this.msg, required this.mine, required this.compacto});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(mine ? 18 : 4),
      bottomRight: Radius.circular(mine ? 4 : 18),
    );
    final time = msg.createdAt;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: EdgeInsets.only(top: compacto ? 2 : 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: mine ? AppColors.navy : Colors.white,
            borderRadius: radius,
            border: mine ? null : Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                msg.text,
                style: TextStyle(color: mine ? Colors.white : AppColors.navy, fontSize: 15, height: 1.35),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time == null ? 'Enviando' : hora(time),
                    style: TextStyle(fontSize: 11, color: mine ? Colors.white.withValues(alpha: 0.65) : AppColors.muted),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.pendiente ? Icons.schedule_rounded : Icons.done_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                      semanticLabel: msg.pendiente ? 'Enviando' : 'Enviado',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  final String text;
  const _DaySeparator(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool enviando;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.focus, required this.enviando, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                minLines: 1,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.mist,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final can = value.text.trim().isNotEmpty && !enviando;
                return IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: can ? onSend : null,
                  style: IconButton.styleFrom(backgroundColor: AppColors.navy, minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.send_rounded),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatVacio extends StatelessWidget {
  final String nombre;
  final List<String> sugerencias;
  final ValueChanged<String> onSugerencia;
  const _ChatVacio({required this.nombre, required this.sugerencias, required this.onSugerencia});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.handshake_rounded, size: 52, color: AppColors.success),
        const SizedBox(height: 12),
        const Text('¡Hicieron match!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
        const SizedBox(height: 6),
        Text(
          'Escríbele a $nombre para acordar dónde y cuándo entregar el paquete.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in sugerencias) ActionChip(label: Text(s), onPressed: () => onSugerencia(s))],
        ),
      ],
    );
  }
}

class _ChatBloqueado extends StatelessWidget {
  final MatchDoc match;
  final String uid;
  const _ChatBloqueado({required this.match, required this.uid});

  @override
  Widget build(BuildContext context) {
    final texto = switch (match.estado) {
      'interesado' => match.soyRemitente(uid)
          ? 'Acepta a este viajero desde el detalle de tu envío para habilitar el chat.'
          : 'El chat se habilita cuando el remitente acepte que lleves su encargo.',
      'rechazado' => 'Este match no se concretó.',
      _ => 'Este chat no está disponible.',
    };
    return EmptyState(icon: Icons.lock_outline_rounded, title: 'Chat bloqueado', message: texto);
  }
}
