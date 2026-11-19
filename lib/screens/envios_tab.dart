import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/matches_controller.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/common.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: lapAppBar('Mis envíos'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo envío', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Encargo>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(error: snap.error!, onRetry: () => setState(() => _stream = LapticonStore.instance.misEncargos()));
          }
          if (!snap.hasData) return const LoadingView(message: 'Cargando tus envíos…');
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Envía tu primer encargo',
                  message: 'Cuéntanos qué envías, a dónde y cuánto pagas. Solo lo verán viajeros con un vuelo en esa ruta antes de tu fecha límite.',
                  action: FilledButton.icon(onPressed: _nuevo, icon: const Icon(Icons.add), label: const Text('Crear envío')),
                ),
              ),
            );
          }
          final activos = items.where((e) => e.estado == 'publicado' || e.estado == 'asignado').toList();
          final cerrados = items.where((e) => e.estado != 'publicado' && e.estado != 'asignado').toList();
          return ListenableBuilder(
            listenable: MatchesController.instance,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                if (activos.isNotEmpty) const SectionTitle('Activos'),
                for (final e in activos) ...[EncargoCard(encargo: e), const SizedBox(height: 12)],
                if (cerrados.isNotEmpty) const SectionTitle('Historial'),
                for (final e in cerrados) ...[EncargoCard(encargo: e), const SizedBox(height: 12)],
              ],
            ),
          );
        },
      ),
    );
  }
}

class EncargoCard extends StatelessWidget {
  final Encargo encargo;
  const EncargoCard({super.key, required this.encargo});

  @override
  Widget build(BuildContext context) {
    final e = encargo;
    final interesados = MatchesController.instance.deEncargo(e.id).where((m) => m.pendiente).length;
    return SurfaceCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EncargoDetailScreen(encargoId: e.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EncargoStatusChip(e.estado),
              const Spacer(),
              if (e.abierto && interesados > 0)
                StatusChip('$interesados ${interesados == 1 ? 'interesado' : 'interesados'}', color: AppColors.warning, icon: Icons.person_search_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: RouteLine(e.ciudadOrigen, e.ciudadDestino)),
              const SizedBox(width: 12),
              PriceTag(e.precio, e.moneda),
            ],
          ),
          const SizedBox(height: 8),
          Text(e.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, height: 1.35)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Pill(Icons.event_outlined, 'Antes del ${fechaCorta(e.fechaLimite)}'),
              Pill(iconoTamano(e.tamano), '${e.tamano.label} · ${kg(e.pesoKg)}'),
              Pill(iconoCategoria(e.categoria), e.categoriaLabel),
            ],
          ),
        ],
      ),
    );
  }
}
