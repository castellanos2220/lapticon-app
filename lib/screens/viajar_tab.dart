import 'package:flutter/material.dart';

import '../demo.dart';
import '../format.dart';
import '../matching.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/matches_controller.dart';
import '../services/ofertas.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/demo_views.dart';
import '../widgets/immersive.dart';
import 'nuevo_viaje_screen.dart';
import 'oferta_detail_screen.dart';

/// Pestaña del viajero: su vuelo activo y SOLO los encargos compatibles con él.
class ViajarTab extends StatefulWidget {
  const ViajarTab({super.key});

  @override
  State<ViajarTab> createState() => _ViajarTabState();
}

class _ViajarTabState extends State<ViajarTab> {
  bool _loading = true;
  Object? _error;
  Viaje? _viaje;
  List<Oferta> _ofertas = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = _viaje == null;
      _error = null;
    });
    try {
      final v = await LapticonApi.instance.miViajeDisponible();
      final ofertas = v == null ? const <Oferta>[] : await buscarOfertas(v);
      if (!mounted) return;
      setState(() {
        _viaje = v;
        _ofertas = ofertas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _nuevoViaje() async {
    final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const NuevoViajeScreen()));
    if (creado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final v = _viaje;
    final demoOfertas = v != null && _ofertas.isEmpty
        ? demoMercado(origen: v.ciudadOrigen, destino: v.ciudadDestino)
        : (v == null ? demoMercado() : const <Encargo>[]);
    final ganancia = _ofertas.fold<double>(0, (a, o) => a + (o.encargo.moneda == 'USD' ? o.encargo.precio : 0));

    return ListenableBuilder(
      listenable: MatchesController.instance,
      builder: (context, _) => ImmersivePage(
        onRefresh: _cargar,
        header: HeroHeader(
          eyebrow: 'Modo viajero',
          title: v == null ? 'Tu próximo vuelo\npaga el viaje' : 'Listo para despegar',
          subtitle: v == null
              ? 'Registra tu vuelo y lleva encargos en tu misma ruta. Tú eliges cuáles.'
              : 'Estos son los encargos que coinciden con tu ruta y fecha.',
          seed: 3,
          trailing: HeroIconButton(icon: Icons.refresh_rounded, tooltip: 'Actualizar', onPressed: _cargar),
          child: _loading
              ? null
              : v == null
                  ? _RegistrarVueloPanel(onTap: _nuevoViaje)
                  : FlightTicket(viaje: v),
        ),
        children: [
          if (_loading)
            const Padding(padding: EdgeInsets.only(top: 40), child: LoadingView(message: 'Buscando tu vuelo…'))
          else if (_error != null && v == null) ...[
            InfoBanner(icon: Icons.cloud_off_rounded, color: AppColors.warning, text: errorText(_error!), action: TextButton(onPressed: _cargar, child: const Text('Reintentar'))),
            const SizedBox(height: 8),
            ..._demoList(context, demoOfertas, v, titulo: 'Encargos que buscan viajero'),
          ] else if (v == null)
            ..._demoList(context, demoOfertas, null, titulo: 'Encargos que buscan viajero')
          else ...[
            if (_error != null) ...[
              InfoBanner(icon: Icons.cloud_off_rounded, color: AppColors.warning, text: errorText(_error!)),
              const SizedBox(height: 4),
            ],
            if (_ofertas.isNotEmpty) ...[
              _GananciaCard(total: ganancia, n: _ofertas.length),
              SectionTitle('Encargos para tu vuelo', trailing: StatusChip('${_ofertas.length}', color: AppColors.success)),
              for (final o in _ofertas) ...[
                OfertaCard(oferta: o, viaje: v, onChanged: _cargar),
                const SizedBox(height: 12),
              ],
            ] else
              ..._demoList(context, demoOfertas, v, titulo: 'Encargos para tu vuelo'),
          ],
        ],
      ),
    );
  }

  List<Widget> _demoList(BuildContext context, List<Encargo> demo, Viaje? v, {required String titulo}) => [
        SectionTitle(titulo),
        DemoSectionNote(
          v == null
              ? 'Ejemplos de encargos publicados. Registra tu vuelo para ver los reales de tu ruta.'
              : 'Aún no hay encargos reales en tu ruta. Así se verán cuando alguien publique uno; desliza hacia abajo para actualizar.',
        ),
        const SizedBox(height: 12),
        for (final e in demo) ...[
          OfertaCard(
            oferta: Oferta(e, const Compatibilidad(compatible: true, razones: [], bloqueos: [])),
            viaje: v,
            onChanged: _cargar,
            demo: true,
            onDemoAccion: v == null ? _nuevoViaje : null,
          ),
          const SizedBox(height: 12),
        ],
      ];
}

class _RegistrarVueloPanel extends StatelessWidget {
  final VoidCallback onTap;
  const _RegistrarVueloPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.airplane_ticket_rounded, color: AppColors.sky),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Número de vuelo, ruta y fecha. Toma menos de un minuto.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, height: 1.35),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navy, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}

class _GananciaCard extends StatelessWidget {
  final double total;
  final int n;
  const _GananciaCard({required this.total, required this.n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF047857), AppColors.success], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$n ${n == 1 ? 'encargo compatible' : 'encargos compatibles'} con tu vuelo',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
          if (total > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Hasta', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                Text(dinero(total, 'USD'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Vuelo del viajero con estética de pase de abordar, sobre la cabecera oscura.
class FlightTicket extends StatelessWidget {
  final Viaje viaje;
  const FlightTicket({super.key, required this.viaje});

  @override
  Widget build(BuildContext context) {
    final v = viaje;
    final dias = v.fecha?.difference(hoyDia()).inDays;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PASE DE ABORDAR', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w800, letterSpacing: 1.6, fontSize: 11)),
              const Spacer(),
              FlightCodeChip(v.numeroVuelo, large: true),
            ],
          ),
          const SizedBox(height: 16),
          RouteCodes(v.ciudadOrigen, v.ciudadDestino, dark: true, codeSize: 30),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_rounded, color: AppColors.sky, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(v.fecha == null ? 'Sin fecha' : fechaLarga(v.fecha!), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              if (dias != null && dias >= 0)
                StatusChip(dias == 0 ? 'Hoy' : (dias == 1 ? 'Mañana' : 'En $dias días'), color: AppColors.sky, icon: Icons.schedule_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class OfertaCard extends StatelessWidget {
  final Oferta oferta;
  final Viaje? viaje;
  final VoidCallback onChanged;
  final bool demo;
  final VoidCallback? onDemoAccion;
  const OfertaCard({super.key, required this.oferta, required this.viaje, required this.onChanged, this.demo = false, this.onDemoAccion});

  @override
  Widget build(BuildContext context) {
    final e = oferta.encargo;
    final mio = demo ? null : MatchesController.instance.miInteresEn(e.id, LapticonStore.instance.uid);
    return SurfaceCard(
      onTap: () async {
        if (demo || viaje == null) {
          await showDemoEncargo(
            context,
            e,
            comoViajero: true,
            accionLabel: onDemoAccion == null ? null : 'Registrar mi vuelo',
            onAccion: onDemoAccion,
          );
          return;
        }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OfertaDetailScreen(oferta: oferta, viaje: viaje!)));
        onChanged();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.kraftSoft, Color(0xFFF0DCC3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconoCategoria(e.categoria), color: AppColors.kraftDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(e.categoriaLabel, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                        if (demo) ...[const SizedBox(width: 6), const DemoBadge()],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(e.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, height: 1.3, fontSize: 13.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriceTag(e.precio, e.moneda, caption: 'Te pagan'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(14)),
            child: RouteCodes(e.ciudadOrigen, e.ciudadDestino, codeSize: 17),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Pill(iconoTamano(e.tamano), '${e.tamano.label} · ${kg(e.pesoKg)}'),
              Pill(Icons.event_outlined, 'Límite ${fechaCorta(e.fechaLimite)}'),
              if (!demo && oferta.compatibilidad.margenDias != null) const Pill(Icons.verified_outlined, 'Compatible', color: AppColors.success),
              if (demo) Pill(Icons.person_outline_rounded, e.senderName),
            ],
          ),
          if (mio != null) ...[
            const SizedBox(height: 12),
            StatusChip(
              mio.esMatch ? '¡Match! Abre el chat' : estadosMatch[mio.estado] ?? mio.estado,
              color: mio.esMatch ? AppColors.success : (mio.pendiente ? AppColors.warning : AppColors.muted),
              icon: mio.esMatch ? Icons.chat_bubble_rounded : Icons.schedule_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
