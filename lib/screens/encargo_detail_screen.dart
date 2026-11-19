import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/matches_controller.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

/// Detalle de un encargo para el REMITENTE: datos, viajeros interesados
/// (aceptar / descartar) y acceso al chat cuando hay match.
class EncargoDetailScreen extends StatefulWidget {
  final String encargoId;
  final bool recienCreado;
  const EncargoDetailScreen({super.key, required this.encargoId, this.recienCreado = false});

  @override
  State<EncargoDetailScreen> createState() => _EncargoDetailScreenState();
}

class _EncargoDetailScreenState extends State<EncargoDetailScreen> {
  late final Stream<Encargo?> _stream = LapticonStore.instance.encargo(widget.encargoId);
  String? _busyId; // match en proceso o 'encargo'

  MatchesController get _matches => MatchesController.instance;

  Future<void> _aceptar(Encargo e, MatchDoc m) async {
    final ok = await confirmar(
      context,
      titulo: 'Aceptar a ${m.travelerName}',
      mensaje: 'Llevará tu encargo en el vuelo ${m.numeroVuelo}${m.fechaViaje != null ? ' del ${fechaCorta(m.fechaViaje!)}' : ''} por ${dinero(e.precio, e.moneda)}.\n\n'
          'Se abrirá un chat entre ustedes y los demás interesados quedarán descartados.',
      ok: 'Aceptar y abrir chat',
    );
    if (!ok || !mounted) return;
    setState(() => _busyId = m.id);
    try {
      await LapticonStore.instance.aceptar(m, _matches.deEncargo(e.id));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: m.id)));
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _descartar(MatchDoc m) async {
    final ok = await confirmar(context, titulo: 'Descartar a ${m.travelerName}', mensaje: 'Ya no verá este encargo como opción.', ok: 'Descartar', peligro: true);
    if (!ok || !mounted) return;
    setState(() => _busyId = m.id);
    try {
      await LapticonStore.instance.rechazar(m);
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _cancelar(Encargo e) async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar envío',
      mensaje: 'Dejará de mostrarse a los viajeros y se descartarán los interesados. Esta acción no se puede deshacer.',
      ok: 'Cancelar envío',
      peligro: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busyId = 'encargo');
    try {
      await LapticonApi.instance.cancelarEncomienda(e.id);
      await LapticonStore.instance.cancelarEncargo(e, _matches.deEncargo(e.id));
      if (mounted) showOk(context, 'Envío cancelado.');
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _entregado(Encargo e) async {
    final ok = await confirmar(context, titulo: '¿Ya llegó tu encargo?', mensaje: 'Confírmalo cuando el destinatario lo haya recibido.', ok: 'Sí, fue entregado');
    if (!ok || !mounted) return;
    setState(() => _busyId = 'encargo');
    try {
      await LapticonStore.instance.marcarEntregado(e);
      if (mounted) showOk(context, '¡Listo! Encargo marcado como entregado.');
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Encargo?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(appBar: lapAppBar('Envío'), body: ErrorView(error: snap.error!, onRetry: () => setState(() {})));
        }
        if (!snap.hasData) return Scaffold(appBar: lapAppBar('Envío'), body: const LoadingView());
        final e = snap.data;
        if (e == null) {
          return Scaffold(
            appBar: lapAppBar('Envío'),
            body: const EmptyState(icon: Icons.search_off_rounded, title: 'No encontramos este envío', message: 'Puede que haya sido eliminado.'),
          );
        }
        return Scaffold(
          appBar: lapAppBar('Tu envío', actions: [
            if (e.abierto)
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (_) => _cancelar(e),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'cancelar', child: ListTile(leading: Icon(Icons.block, color: AppColors.danger), title: Text('Cancelar envío'))),
                ],
              ),
          ]),
          body: BusyOverlay(
            busy: _busyId == 'encargo',
            child: ListenableBuilder(
              listenable: _matches,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  if (widget.recienCreado && e.abierto) ...[
                    const InfoBanner(
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      text: '¡Publicado! Te avisaremos aquí cuando un viajero con vuelo compatible quiera llevarlo.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  EncargoResumen(encargo: e),
                  ..._seccionEstado(e),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _seccionEstado(Encargo e) {
    final todos = _matches.deEncargo(e.id);
    switch (e.estado) {
      case 'publicado':
        final interesados = todos.where((m) => m.pendiente).toList();
        return [
          SectionTitle('Viajeros interesados', trailing: interesados.isEmpty ? null : StatusChip('${interesados.length}', color: AppColors.warning)),
          if (interesados.isEmpty)
            SurfaceCard(
              child: Column(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: AppColors.navyLight, size: 32),
                  const SizedBox(height: 10),
                  const Text('Esperando viajeros', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
                  const SizedBox(height: 6),
                  Text(
                    'Tu encargo solo lo ven viajeros con vuelo ${e.ciudadOrigen} → ${e.ciudadDestino} entre hoy y el ${fechaCorta(e.fechaLimite)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          for (final m in interesados) ...[
            _InteresadoCard(
              match: m,
              encargo: e,
              busy: _busyId == m.id,
              onAceptar: () => _aceptar(e, m),
              onDescartar: () => _descartar(m),
            ),
            const SizedBox(height: 10),
          ],
        ];
      case 'asignado':
        final m = _matches.byId(e.matchId);
        return [
          const SectionTitle('Viajero asignado'),
          if (m == null)
            const SurfaceCard(child: Text('Cargando datos del viajero…', style: TextStyle(color: AppColors.muted)))
          else
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(m.travelerName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.travelerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(children: [
                              FlightCodeChip(m.numeroVuelo),
                              const SizedBox(width: 8),
                              if (m.fechaViaje != null) Text(fechaCorta(m.fechaViaje!), style: const TextStyle(color: AppColors.muted)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: m.noLeidoPara(LapticonStore.instance.uid) ? 'Abrir chat · mensajes nuevos' : 'Abrir chat',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: m.id))),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _entregado(e),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Marcar como entregado'),
                    ),
                  ),
                ],
              ),
            ),
        ];
      case 'entregado':
        return [
          const SizedBox(height: 16),
          InfoBanner(
            icon: Icons.verified_rounded,
            color: AppColors.success,
            text: 'Encargo entregado. ¡Gracias por usar Lapticon!',
            action: e.matchId == null
                ? null
                : TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: e.matchId!))),
                    child: const Text('Ver chat'),
                  ),
          ),
        ];
      default:
        return [
          const SizedBox(height: 16),
          const InfoBanner(icon: Icons.block, color: AppColors.muted, text: 'Este envío fue cancelado.'),
        ];
    }
  }
}

/// Tarjeta con todos los datos del encargo (compartida con la vista del viajero).
class EncargoResumen extends StatelessWidget {
  final Encargo encargo;
  final bool mostrarEstado;
  const EncargoResumen({super.key, required this.encargo, this.mostrarEstado = true});

  @override
  Widget build(BuildContext context) {
    final e = encargo;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mostrarEstado) ...[EncargoStatusChipOnDark(e.estado), const SizedBox(height: 12)],
                RouteLine(e.ciudadOrigen, e.ciudadDestino, size: 20, color: Colors.white),
                const SizedBox(height: 8),
                Text('Entregar antes del ${fechaLarga(e.fechaLimite)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: AppColors.kraftSoft, borderRadius: BorderRadius.circular(12)),
                      child: Icon(iconoCategoria(e.categoria), color: const Color(0xFF8A5A2B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.categoriaLabel, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                          const SizedBox(height: 4),
                          Text(e.descripcion, style: const TextStyle(height: 1.4, color: AppColors.navy)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Dato(icon: iconoTamano(e.tamano), titulo: 'Tamaño', valor: e.tamano.label, sub: e.tamano.hint)),
                    Expanded(child: _Dato(icon: Icons.scale_outlined, titulo: 'Peso', valor: kg(e.pesoKg))),
                    Expanded(child: _Dato(icon: Icons.payments_outlined, titulo: 'Pago', valor: dinero(e.precio, e.moneda), color: AppColors.success)),
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

class EncargoStatusChipOnDark extends StatelessWidget {
  final String estado;
  const EncargoStatusChipOnDark(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(estadosEncargo[estado] ?? estado, style: const TextStyle(color: AppColors.sky, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;
  final String? sub;
  final Color color;
  const _Dato({required this.icon, required this.titulo, required this.valor, this.sub, this.color = AppColors.navy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(height: 4),
        Text(titulo, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        Text(valor, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        if (sub != null) Text(sub!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _InteresadoCard extends StatelessWidget {
  final MatchDoc match;
  final Encargo encargo;
  final bool busy;
  final VoidCallback onAceptar;
  final VoidCallback onDescartar;
  const _InteresadoCard({required this.match, required this.encargo, required this.busy, required this.onAceptar, required this.onDescartar});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final margen = m.fechaViaje == null ? null : encargo.fechaLimite.difference(m.fechaViaje!).inDays;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(m.travelerName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.travelerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    const Text('Quiere llevar tu encargo', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FlightCodeChip(m.numeroVuelo),
              if (m.fechaViaje != null) Pill(Icons.event_available_outlined, 'Vuela el ${fechaCorta(m.fechaViaje!)}'),
              if (margen != null && margen >= 0)
                Pill(Icons.verified_outlined, margen == 0 ? 'Mismo día del límite' : '$margen días de margen', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDescartar,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAceptar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.handshake_rounded),
                  label: const Text('Aceptar · hacer match'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
