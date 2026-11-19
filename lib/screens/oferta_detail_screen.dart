import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/matches_controller.dart';
import '../services/ofertas.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'encargo_detail_screen.dart';

/// Detalle de un encargo para el VIAJERO: por qué es compatible con su vuelo
/// y el botón para mostrar interés. El chat se abre cuando el remitente acepta.
class OfertaDetailScreen extends StatefulWidget {
  final Oferta oferta;
  final Viaje viaje;
  const OfertaDetailScreen({super.key, required this.oferta, required this.viaje});

  @override
  State<OfertaDetailScreen> createState() => _OfertaDetailScreenState();
}

class _OfertaDetailScreenState extends State<OfertaDetailScreen> {
  bool _busy = false;

  Future<void> _meInteresa() async {
    setState(() => _busy = true);
    try {
      await LapticonStore.instance.meInteresa(widget.oferta.encargo, widget.viaje);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showOk(context, 'Le avisamos a ${widget.oferta.encargo.senderName}. Si te acepta, se abre el chat.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retirar(MatchDoc m) async {
    final ok = await confirmar(context, titulo: 'Retirar interés', mensaje: 'El remitente ya no te verá como opción para este encargo.', ok: 'Retirar', peligro: true);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await LapticonStore.instance.retirarInteres(m);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.oferta.encargo;
    final c = widget.oferta.compatibilidad;
    return Scaffold(
      appBar: lapAppBar('Encargo'),
      body: ListenableBuilder(
        listenable: MatchesController.instance,
        builder: (context, _) {
          final mio = MatchesController.instance.miInteresEn(e.id, LapticonStore.instance.uid);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    EncargoResumen(encargo: e, mostrarEstado: false),
                    const SectionTitle('Compatible con tu vuelo'),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            FlightCodeChip(widget.viaje.numeroVuelo),
                            const SizedBox(width: 10),
                            const Text('Tu vuelo', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 12),
                          for (final r in c.razones)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(r, style: const TextStyle(height: 1.35, color: AppColors.navy))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SectionTitle('Publicado por'),
                    SurfaceCard(
                      child: Row(
                        children: [
                          Avatar(e.senderName),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.senderName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const InfoBanner(
                      icon: Icons.shield_outlined,
                      color: AppColors.warning,
                      text: 'Revisa el contenido antes de recibirlo. No transportes nada que no puedas declarar en la aerolínea o la aduana.',
                    ),
                  ],
                ),
              ),
              _AccionInferior(
                estado: mio?.estado,
                encargoAbierto: e.abierto,
                busy: _busy,
                onInteresa: _meInteresa,
                onRetirar: mio == null ? null : () => _retirar(mio),
                onChat: mio == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: mio.id))),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccionInferior extends StatelessWidget {
  final String? estado;
  final bool encargoAbierto;
  final bool busy;
  final VoidCallback onInteresa;
  final VoidCallback? onRetirar;
  final VoidCallback? onChat;
  const _AccionInferior({required this.estado, required this.encargoAbierto, required this.busy, required this.onInteresa, this.onRetirar, this.onChat});

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (estado) {
      case null:
        child = PrimaryButton(
          label: encargoAbierto ? 'Me interesa llevarlo' : 'Ya no está disponible',
          icon: Icons.volunteer_activism_rounded,
          busy: busy,
          onPressed: encargoAbierto ? onInteresa : null,
        );
      case 'interesado':
        child = Row(
          children: [
            const Expanded(
              child: Text('Esperando que el remitente acepte. Te avisaremos con un match.', style: TextStyle(color: AppColors.muted, height: 1.35)),
            ),
            TextButton(onPressed: busy ? null : onRetirar, child: const Text('Retirar')),
          ],
        );
      case 'match':
        child = PrimaryButton(label: 'Abrir chat', icon: Icons.chat_bubble_rounded, color: AppColors.success, onPressed: onChat);
      case 'rechazado':
        child = const Text('El remitente eligió a otro viajero para este encargo.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted));
      default:
        child = const Text('Retiraste tu interés en este encargo.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      child: SafeArea(top: false, child: child),
    );
  }
}
