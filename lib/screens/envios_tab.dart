import 'package:flutter/material.dart';

import '../demo.dart';
import '../format.dart';
import '../models.dart';
import '../services/matches_controller.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/demo_views.dart';
import '../widgets/immersive.dart';
import 'encargo_detail_screen.dart';
import 'nuevo_encargo_screen.dart';

/// Pestaña del remitente: sus encargos y cuántos viajeros se interesaron.
class EnviosTab extends StatefulWidget {
  const EnviosTab({super.key});

  @override
  State<EnviosTab> createState() => _EnviosTabState();
}

class _EnviosTabState extends State<EnviosTab> {
  late Stream<List<Encargo>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = LapticonStore.instance.misEncargos();
  }

  void _nuevo() => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoEncargoScreen()));

  String get _saludo {
    final n = LapticonStore.instance.miNombre.split(' ').first;
    final h = DateTime.now().hour;
    final s = h < 12 ? 'Buenos días' : (h < 19 ? 'Buenas tardes' : 'Buenas noches');
    return '$s, $n';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Encargo>>(
      stream: _stream,
      builder: (context, snap) {
        return ListenableBuilder(
          listenable: MatchesController.instance,
          builder: (context, _) {
            final items = snap.data ?? const <Encargo>[];
            final demo = snap.hasData && items.isEmpty;
            final mostrar = demo ? demoMisEnvios() : items;
            int interesados(Encargo e) =>
                demo ? demoInteresados(e.id) : MatchesController.instance.deEncargo(e.id).where((m) => m.pendiente).length;
            final activos = mostrar.where((e) => e.estado == 'publicado' || e.estado == 'asignado').toList();
            final cerrados = mostrar.where((e) => e.estado != 'publicado' && e.estado != 'asignado').toList();
            final totalInteresados = mostrar.where((e) => e.abierto).fold<int>(0, (a, e) => a + interesados(e));
            final entregados = mostrar.where((e) => e.estado == 'entregado').length;

            return ImmersivePage(
              onRefresh: () async => setState(() => _stream = LapticonStore.instance.misEncargos()),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _nuevo,
                backgroundColor: AppColors.royal,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo envío', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              header: HeroHeader(
                eyebrow: 'Modo remitente',
                title: _saludo,
                subtitle: '¿Qué quieres enviar hoy? Tus encargos viajan con personas que ya van para allá.',
                seed: 2,
                child: HeroStats([
                  ('${activos.length}', 'Activos'),
                  ('$totalInteresados', 'Interesados'),
                  ('$entregados', 'Entregados'),
                ]),
              ),
              children: [
                if (snap.hasError)
                  ErrorView(error: snap.error!, onRetry: () => setState(() => _stream = LapticonStore.instance.misEncargos()))
                else if (!snap.hasData)
                  const Padding(padding: EdgeInsets.only(top: 40), child: LoadingView(message: 'Cargando tus envíos…'))
                else ...[
                  _NuevoEnvioBanner(onTap: _nuevo),
                  if (demo) ...[
                    const SizedBox(height: 14),
                    const DemoSectionNote('Aún no tienes envíos. Así se verán cuando publiques el primero. Toca uno para ver el detalle.'),
                  ],
                  if (activos.isNotEmpty) const SectionTitle('Activos'),
                  for (final e in activos) ...[
                    EncargoCard(encargo: e, interesados: interesados(e), demo: demo, onNuevo: _nuevo),
                    const SizedBox(height: 12),
                  ],
                  if (cerrados.isNotEmpty) const SectionTitle('Historial'),
                  for (final e in cerrados) ...[
                    EncargoCard(encargo: e, interesados: 0, demo: demo, onNuevo: _nuevo),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _NuevoEnvioBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NuevoEnvioBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.kraft, Color(0xFFC08A4E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Publica un envío en 3 pasos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                SizedBox(height: 3),
                Text('Ruta, qué envías y cuánto pagas. Solo lo ven viajeros compatibles.', style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppColors.skySoft, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: AppColors.royal, size: 18),
          ),
        ],
      ),
    );
  }
}

class EncargoCard extends StatelessWidget {
  final Encargo encargo;
  final int interesados;
  final bool demo;
  final VoidCallback? onNuevo;
  const EncargoCard({super.key, required this.encargo, required this.interesados, this.demo = false, this.onNuevo});

  @override
  Widget build(BuildContext context) {
    final e = encargo;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () {
        if (demo || esDemo(e.id)) {
          showDemoEncargo(context, e, comoViajero: false, accionLabel: 'Crear mi primer envío', onAccion: onNuevo);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EncargoDetailScreen(encargoId: e.id)));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                EncargoStatusChip(e.estado),
                if (demo) ...[const SizedBox(width: 6), const DemoBadge()],
                const Spacer(),
                if (e.abierto && interesados > 0)
                  StatusChip('$interesados ${interesados == 1 ? 'interesado' : 'interesados'}', color: AppColors.warning, icon: Icons.person_search_rounded),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: RouteCodes(e.ciudadOrigen, e.ciudadDestino),
          ),
          const _Perforation(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.kraftSoft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(iconoCategoria(e.categoria), color: AppColors.kraftDeep, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(
                        'Antes del ${fechaCorta(e.fechaLimite)} · ${e.tamano.label} · ${kg(e.pesoKg)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                PriceTag(e.precio, e.moneda),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea perforada de "boleto" con muescas laterales.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, c) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate((c.maxWidth / 9).floor(), (_) => Container(width: 4, height: 1.4, color: AppColors.line)),
              ),
            ),
          ),
          Positioned(left: -8, child: _notch()),
          Positioned(right: -8, child: _notch()),
        ],
      ),
    );
  }

  Widget _notch() => Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.mist, shape: BoxShape.circle));
}
