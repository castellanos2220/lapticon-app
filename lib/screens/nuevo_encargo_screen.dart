import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/city_field.dart';
import '../widgets/common.dart';
import 'encargo_detail_screen.dart';

/// Asistente de 3 pasos para publicar un encargo:
///   1. Ruta y fecha límite · 2. Qué envías y tamaño · 3. Precio que pagas y revisión.
class NuevoEncargoScreen extends StatefulWidget {
  const NuevoEncargoScreen({super.key});

  @override
  State<NuevoEncargoScreen> createState() => _NuevoEncargoScreenState();
}

class _NuevoEncargoScreenState extends State<NuevoEncargoScreen> {
  static const _pasos = ['Ruta y fecha', '¿Qué envías?', 'Tu oferta'];
  final _forms = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];

  int _paso = 0;
  bool _busy = false;
  List<String> _ciudades = ciudadesRespaldo;
  bool _cargandoCiudades = true;

  // Paso 1
  String _origen = '';
  String _destino = '';
  DateTime? _fecha;
  int _swapKey = 0;
  final _fechaCtrl = TextEditingController();

  // Paso 2
  String _categoria = 'documentos';
  final _desc = TextEditingController();
  Tamano _tamano = Tamano.pequeno;
  double _peso = 1;

  // Paso 3
  String _moneda = 'USD';
  double _precio = 20;

  @override
  void initState() {
    super.initState();
    LapticonApi.instance.ciudades().then((c) {
      if (mounted) setState(() {
        _ciudades = c;
        _cargandoCiudades = false;
      });
    });
  }

  @override
  void dispose() {
    _fechaCtrl.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Fecha máxima de entrega',
    );
    if (picked != null) {
      setState(() {
        _fecha = dia(picked);
        _fechaCtrl.text = fechaLarga(_fecha!);
      });
    }
  }

  void _cambiarMoneda(String m) {
    if (m == _moneda) return;
    setState(() {
      _moneda = m;
      _precio = m == 'COP' ? 80000 : 20;
    });
  }

  double get _paso5 => _moneda == 'COP' ? 10000 : 5;
  List<double> get _rapidos => _moneda == 'COP' ? const [40000, 80000, 150000, 250000] : const [10, 20, 35, 50];

  void _siguiente() {
    if (!(_forms[_paso].currentState?.validate() ?? false)) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (_paso < 2) {
      FocusScope.of(context).unfocus();
      setState(() => _paso++);
    } else {
      _publicar();
    }
  }

  Future<void> _publicar() async {
    final store = LapticonStore.instance;
    final api = LapticonApi.instance;
    setState(() => _busy = true);
    String? renderId;
    try {
      final desc = _desc.text.trim();
      final id = await api.crearEncomienda(
        ciudadOrigen: _origen,
        ciudadDestino: _destino,
        observaciones: '${categorias[_categoria]} · ${_tamano.label} · ${kg(_peso)} · $desc',
        moneda: _moneda,
        valor: _precio,
        extra: {
          'descripcion': desc,
          'categoria': _categoria,
          'tamano': _tamano.code,
          'pesoKg': _peso,
          'fechaLimite': ymd(_fecha!),
        },
      );
      renderId = id;
      await store.crearEncargo(Encargo(
        id: id,
        senderId: store.uid,
        senderName: store.miNombre,
        ciudadOrigen: _origen,
        ciudadDestino: _destino,
        fechaLimite: _fecha!,
        descripcion: desc,
        categoria: _categoria,
        tamano: _tamano,
        pesoKg: _peso,
        precio: _precio,
        moneda: _moneda,
      ));
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EncargoDetailScreen(encargoId: id, recienCreado: true)));
    } catch (e) {
      // Si el backend creó la encomienda pero Firestore falló, se anula para no dejarla huérfana.
      if (renderId != null) api.cancelarEncomienda(renderId).ignore();
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _paso == 0 && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso > 0 && !_busy) setState(() => _paso--);
      },
      child: Scaffold(
        appBar: lapAppBar(
          'Nuevo envío',
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: _StepIndicator(paso: _paso, titulos: _pasos),
          ),
        ),
        body: BusyOverlay(
          busy: _busy,
          message: 'Publicando tu envío…',
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_paso),
                        child: switch (_paso) {
                          0 => _paso1(),
                          1 => _paso2(),
                          _ => _paso3(),
                        },
                      ),
                    ),
                  ),
                ),
                _barraInferior(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _barraInferior() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          if (_paso > 0) ...[
            SizedBox(
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _busy ? null : () => setState(() => _paso--),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: PrimaryButton(
              label: _paso < 2 ? 'Continuar' : 'Publicar envío',
              icon: _paso < 2 ? Icons.arrow_forward_rounded : Icons.send_rounded,
              busy: _busy,
              onPressed: _siguiente,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- paso 1
  Widget _paso1() {
    return Form(
      key: _forms[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('¿De dónde a dónde va?', 'Solo verán tu encargo viajeros con un vuelo en esta misma ruta.'),
          if (_cargandoCiudades) const LinearProgressIndicator(minHeight: 2, color: AppColors.sky),
          const SizedBox(height: 12),
          CityField(
            key: ValueKey('o$_swapKey'),
            label: 'Ciudad de origen',
            icon: Icons.trip_origin_rounded,
            value: _origen,
            cities: _ciudades,
            exclude: _destino.isEmpty ? null : _destino,
            onChanged: (c) => setState(() => _origen = c),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filledTonal(
              tooltip: 'Intercambiar origen y destino',
              onPressed: () => setState(() {
                final t = _origen;
                _origen = _destino;
                _destino = t;
                _swapKey++;
              }),
              icon: const Icon(Icons.swap_vert_rounded),
            ),
          ),
          CityField(
            key: ValueKey('d$_swapKey'),
            label: 'Ciudad de destino',
            icon: Icons.place_rounded,
            value: _destino,
            cities: _ciudades,
            exclude: _origen.isEmpty ? null : _origen,
            onChanged: (c) => setState(() => _destino = c),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _fechaCtrl,
            readOnly: true,
            onTap: _elegirFecha,
            decoration: fieldDeco(
              'Fecha máxima de entrega',
              icon: Icons.event_rounded,
              helper: 'El viajero debe volar este día o antes.',
              suffix: const Icon(Icons.expand_more_rounded),
            ),
            validator: (_) => _fecha == null ? 'Elige la fecha' : null,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- paso 2
  Widget _paso2() {
    return Form(
      key: _forms[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('¿Qué vas a enviar?', 'Una buena descripción da confianza al viajero y acelera el match.'),
          const SizedBox(height: 4),
          const Text('Categoría', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in categorias.entries)
                ChoiceChip(
                  avatar: Icon(iconoCategoria(entry.key), size: 18),
                  label: Text(entry.value),
                  selected: _categoria == entry.key,
                  onSelected: (_) => setState(() => _categoria = entry.key),
                  selectedColor: AppColors.skySoft,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _desc,
            maxLines: 4,
            minLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDeco('Descripción', hint: 'Ej: 2 libros de medicina en caja sellada, sin líquidos.'),
            validator: (v) => (v ?? '').trim().length < 10 ? 'Describe el contenido (mínimo 10 caracteres)' : null,
          ),
          const SizedBox(height: 12),
          const Text('Tamaño', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in Tamano.values) ...[
                Expanded(child: _SizeCard(tamano: t, selected: _tamano == t, onTap: () => setState(() {
                  _tamano = t;
                  _peso = math.min(_peso, t.maxKg);
                }))),
                if (t != Tamano.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text('Peso aproximado', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
              const Spacer(),
              Text(kg(_peso), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.navy)),
            ],
          ),
          Slider(
            value: _peso,
            min: 0.5,
            max: _tamano.maxKg,
            divisions: ((_tamano.maxKg - 0.5) * 2).round(),
            label: kg(_peso),
            activeColor: AppColors.navy,
            onChanged: (v) => setState(() => _peso = v),
          ),
          Text('Máximo para tamaño ${_tamano.label.toLowerCase()}: ${kg(_tamano.maxKg)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.gpp_maybe_outlined,
            color: AppColors.warning,
            text: 'No se permiten líquidos inflamables, dinero en efectivo, armas, drogas ni nada prohibido por la aerolínea o la aduana.',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- paso 3
  Widget _paso3() {
    return Form(
      key: _forms[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Titulo('¿Cuánto pagas por llevarlo?', 'Es lo que recibirá el viajero que acepte. Lo verá antes de decidir.'),
          Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'USD', label: Text('USD')),
                ButtonSegment(value: 'COP', label: Text('COP')),
              ],
              selected: {_moneda},
              onSelectionChanged: (s) => _cambiarMoneda(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Bajar',
                  iconSize: 28,
                  onPressed: _precio > _paso5 ? () => setState(() => _precio -= _paso5) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(dinero(_precio, _moneda), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.success)),
                      ),
                      const Text('pago al viajero', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Subir',
                  iconSize: 28,
                  onPressed: () => setState(() => _precio += _paso5),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final v in _rapidos)
                ChoiceChip(
                  label: Text(dinero(v, _moneda)),
                  selected: _precio == v,
                  onSelected: (_) => setState(() => _precio = v),
                  selectedColor: AppColors.skySoft,
                  showCheckmark: false,
                ),
            ],
          ),
          FormField<double>(
            validator: (_) => _precio <= 0 ? 'El pago debe ser mayor que cero' : null,
            builder: (state) => state.hasError
                ? Padding(padding: const EdgeInsets.only(top: 8), child: Text(state.errorText!, style: const TextStyle(color: AppColors.danger)))
                : const SizedBox.shrink(),
          ),
          const SectionTitle('Revisa tu envío'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteLine(_origen, _destino),
                const SizedBox(height: 10),
                Text(_desc.text.trim(), style: const TextStyle(color: AppColors.navy, height: 1.35)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (_fecha != null) Pill(Icons.event_outlined, 'Antes del ${fechaCorta(_fecha!)}'),
                    Pill(iconoTamano(_tamano), '${_tamano.label} · ${kg(_peso)}'),
                    Pill(iconoCategoria(_categoria), categorias[_categoria] ?? ''),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoBanner(
            icon: Icons.chat_bubble_outline_rounded,
            text: 'Cuando un viajero compatible se interese, te avisaremos. Al aceptarlo, se abre un chat entre ustedes para acordar la entrega.',
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  const _Titulo(this.titulo, this.subtitulo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
          const SizedBox(height: 6),
          Text(subtitulo, style: const TextStyle(color: AppColors.muted, height: 1.4)),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int paso;
  final List<String> titulos;
  const _StepIndicator({required this.paso, required this.titulos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paso ${paso + 1} de ${titulos.length} · ${titulos[paso]}',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < titulos.length; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= paso ? AppColors.navy : AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (i < titulos.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final Tamano tamano;
  final bool selected;
  final VoidCallback onTap;
  const _SizeCard({required this.tamano, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${tamano.label}, ${tamano.hint}, hasta ${kg(tamano.maxKg)}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.skySoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.sky : AppColors.line, width: selected ? 2 : 1),
            ),
            child: Column(
              children: [
                Icon(iconoTamano(tamano), size: 30, color: selected ? AppColors.navy : AppColors.muted),
                const SizedBox(height: 6),
                Text(tamano.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(tamano.hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                Text('≤ ${kg(tamano.maxKg)}', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
