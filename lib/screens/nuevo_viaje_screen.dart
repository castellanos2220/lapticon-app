import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/city_field.dart';
import '../widgets/common.dart';

/// Registro del vuelo del viajero (backend: un viaje activo a la vez).
class NuevoViajeScreen extends StatefulWidget {
  const NuevoViajeScreen({super.key});

  @override
  State<NuevoViajeScreen> createState() => _NuevoViajeScreenState();
}

class _NuevoViajeScreenState extends State<NuevoViajeScreen> {
  final _form = GlobalKey<FormState>();
  final _vuelo = TextEditingController();
  final _fechaCtrl = TextEditingController();
  List<String> _ciudades = ciudadesRespaldo;
  String _origen = '';
  String _destino = '';
  DateTime? _fecha;
  int _swapKey = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    LapticonApi.instance.ciudades().then((c) {
      if (mounted) setState(() => _ciudades = c);
    });
  }

  @override
  void dispose() {
    _vuelo.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Fecha del vuelo',
    );
    if (picked != null) {
      setState(() {
        _fecha = dia(picked);
        _fechaCtrl.text = fechaLarga(_fecha!);
      });
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _busy = true);
    try {
      await LapticonApi.instance.crearViaje(
        numeroVuelo: _vuelo.text.replaceAll(' ', '').toUpperCase(),
        ciudadOrigen: _origen,
        ciudadDestino: _destino,
        fecha: _fecha!,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: lapAppBar('Registrar vuelo'),
      body: BusyOverlay(
        busy: _busy,
        message: 'Registrando tu vuelo…',
        child: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const Text(
                  'Con tu vuelo calculamos qué encargos puedes llevar: misma ruta y fecha límite igual o posterior a tu viaje.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _vuelo,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')), LengthLimitingTextInputFormatter(8)],
                  style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18),
                  decoration: fieldDeco('Código del vuelo', icon: Icons.flight_rounded, hint: 'AV010', helper: 'Está en tu tiquete o pase de abordar.'),
                  validator: (v) {
                    final code = (v ?? '').replaceAll(' ', '').toUpperCase();
                    return RegExp(r'^([A-Z][A-Z0-9]|[0-9][A-Z])\d{1,4}[A-Z]?$').hasMatch(code) ? null : 'Código no válido (ej: AV010, IB6585)';
                  },
                ),
                const SizedBox(height: 18),
                CityField(
                  key: ValueKey('o$_swapKey'),
                  label: 'Sale de',
                  icon: Icons.flight_takeoff_rounded,
                  value: _origen,
                  cities: _ciudades,
                  exclude: _destino.isEmpty ? null : _destino,
                  onChanged: (c) => setState(() => _origen = c),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filledTonal(
                    tooltip: 'Intercambiar',
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
                  label: 'Llega a',
                  icon: Icons.flight_land_rounded,
                  value: _destino,
                  cities: _ciudades,
                  exclude: _origen.isEmpty ? null : _origen,
                  onChanged: (c) => setState(() => _destino = c),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _fechaCtrl,
                  readOnly: true,
                  onTap: _elegirFecha,
                  decoration: fieldDeco('Fecha del vuelo', icon: Icons.event_rounded, suffix: const Icon(Icons.expand_more_rounded)),
                  validator: (_) => _fecha == null ? 'Elige la fecha' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Registrar vuelo', icon: Icons.check_rounded, busy: _busy, onPressed: _guardar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
