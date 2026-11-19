import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api.dart';
import '../theme.dart';

/// Campo de ciudad con búsqueda (sin importar tildes ni mayúsculas).
/// Solo acepta ciudades del catálogo del backend, escritas tal como el backend las espera.
class CityField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> cities;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String? exclude; // no permitir la misma ciudad que el otro campo

  const CityField({
    super.key,
    required this.label,
    required this.value,
    required this.cities,
    required this.onChanged,
    this.icon = Icons.location_on_outlined,
    this.exclude,
  });

  String? _match(String text) {
    final n = normalizeCity(text);
    if (n.isEmpty) return null;
    for (final c in cities) {
      if (normalizeCity(c) == n) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<String>(
        initialValue: TextEditingValue(text: value),
        optionsBuilder: (tev) {
          final q = normalizeCity(tev.text);
          final pool = exclude == null ? cities : cities.where((c) => normalizeCity(c) != normalizeCity(exclude!)).toList();
          if (q.isEmpty) {
            return ciudadesPopulares.where((p) => pool.any((c) => normalizeCity(c) == normalizeCity(p)));
          }
          final starts = <String>[];
          final contains = <String>[];
          for (final c in pool) {
            final n = normalizeCity(c);
            if (n.startsWith(q)) {
              starts.add(c);
            } else if (n.contains(q)) {
              contains.add(c);
            }
            if (starts.length >= 25) break;
          }
          return [...starts, ...contains].take(25);
        },
        onSelected: (c) {
          FocusScope.of(context).unfocus();
          onChanged(c);
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: fieldDeco(label, icon: icon, hint: 'Escribe para buscar'),
          onChanged: (t) => onChanged(_match(t) ?? ''),
          validator: (t) {
            if (t == null || t.trim().isEmpty) return 'Elige una ciudad';
            final m = _match(t);
            if (m == null) return 'Elige una ciudad de la lista';
            if (exclude != null && normalizeCity(m) == normalizeCity(exclude!)) return 'El origen y el destino deben ser distintos';
            return null;
          },
        ),
        optionsViewBuilder: (context, onSelect, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280, maxWidth: constraints.maxWidth),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final c = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city_rounded, color: AppColors.navyLight),
                    title: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => onSelect(c),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
