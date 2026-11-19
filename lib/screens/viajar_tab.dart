import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/matches_controller.dart';
import '../services/ofertas.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
    return Scaffold(
      appBar: lapAppBar('Viajar', actions: [
        IconButton(tooltip: 'Actualizar', onPressed: _cargar, icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: _loading
          ? const LoadingView(message: 'Buscando tu vuelo…')
          : RefreshIndicator(
              onRefresh: _cargar,
              child: _error != null && _viaje == null
                  ? ListView(children: [ErrorView(error: _error!, onRetry: _cargar)])
                  : _viaje == null
                      ? ListView(children: [
                          EmptyState(
                            icon: Icons.flight_takeoff_rounded,
                            title: '¿Tienes un vuelo próximo?',
                            message: 'Regístralo y te mostraremos solo los encargos que van en tu misma ruta y llegan a tiempo. Ganas dinero llevándolos.',
                            action: FilledButton.icon(onPressed: _nuevoViaje, icon: const Icon(Icons.add), label: const Text('Registrar mi vuelo')),
                          ),
                        ])
                      : ListenableBuilder(
                          listenable: MatchesController.instance,
                          builder: (context, _) => ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            children: [
                              FlightTicket(viaje: _viaje!),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                InfoBanner(icon: Icons.cloud_off_rounded, color: AppColors.warning, text: errorText(_error!)),
                              ],
                              SectionTitle(
                                'Encargos para tu vuelo',
                                trailing: _ofertas.isEmpty ? null : StatusChip('${_ofertas.length}', color: AppColors.success),
                              ),
                              if (_ofertas.isEmpty)
                                const SurfaceCard(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, color: AppColors.navyLight, size: 32),
                                      SizedBox(height: 10),
                                      Text('Aún no hay encargos compatibles', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                                      SizedBox(height: 6),
                                      Text(
                                        'Cuando alguien publique un envío en tu ruta con fecha límite igual o posterior a tu vuelo, aparecerá aquí. Desliza hacia abajo para actualizar.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.muted, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              for (final o in _ofertas) ...[
                                OfertaCard(oferta: o, viaje: _viaje!, onChanged: _cargar),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
            ),
    );
  }
}

/// Vuelo del viajero con estética de pase de abordar.
class FlightTicket extends StatelessWidget {
  final Viaje viaje;
  const FlightTicket({super.key, required this.viaje});

  @override
  Widget build(BuildContext context) {
    final v = viaje;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x330B1D39), blurRadius: 20, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TU VUELO', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
              const Spacer(),
              FlightCodeChip(v.numeroVuelo, large: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Ciudad(nombre: v.ciudadOrigen, etiqueta: 'Sale de')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.flight_rounded, color: AppColors.sky, size: 30),
              ),
              Expanded(child: _Ciudad(nombre: v.ciudadDestino, etiqueta: 'Llega a', alignEnd: true)),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_rounded, color: AppColors.sky, size: 18),
              const SizedBox(width: 6),
              Text(v.fecha == null ? 'Sin fecha' : fechaLarga(v.fecha!), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ciudad extends StatelessWidget {
  final String nombre;
  final String etiqueta;
  final bool alignEnd;
  const _Ciudad({required this.nombre, required this.etiqueta, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        Text(nombre, maxLines: 2, textAlign: alignEnd ? TextAlign.end : TextAlign.start, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class OfertaCard extends StatelessWidget {
  final Oferta oferta;
  final Viaje viaje;
  final VoidCallback onChanged;
  const OfertaCard({super.key, required this.oferta, required this.viaje, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final e = oferta.encargo;
    final mio = MatchesController.instance.miInteresEn(e.id, LapticonStore.instance.uid);
    return SurfaceCard(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => OfertaDetailScreen(oferta: oferta, viaje: viaje)));
        onChanged();
      },
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
                    const SizedBox(height: 2),
                    Text(e.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriceTag(e.precio, e.moneda, caption: 'Te pagan'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Pill(iconoTamano(e.tamano), '${e.tamano.label} · ${kg(e.pesoKg)}'),
              Pill(Icons.event_outlined, 'Límite ${fechaCorta(e.fechaLimite)}'),
              if (oferta.compatibilidad.margenDias != null)
                Pill(Icons.verified_outlined, 'Compatible', color: AppColors.success),
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
