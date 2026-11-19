import 'package:intl/intl.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Fecha de calendario sin hora, en UTC, para comparar días sin problemas de zona horaria.
DateTime dia(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime hoyDia() => dia(DateTime.now());

/// YYYY-MM-DD
String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String fechaLarga(DateTime d) => DateFormat("EEE d 'de' MMM yyyy", 'es').format(d);
String fechaCorta(DateTime d) => DateFormat('d MMM', 'es').format(d);
String hora(DateTime d) => DateFormat('HH:mm', 'es').format(d.toLocal());

/// "Hoy", "Ayer" o la fecha corta, para separadores del chat y listas.
String diaRelativo(DateTime d) {
  final local = d.toLocal();
  final hoy = DateTime.now();
  final a = DateTime(local.year, local.month, local.day);
  final b = DateTime(hoy.year, hoy.month, hoy.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return DateFormat("EEEE d 'de' MMMM", 'es').format(local);
}

String horaOFecha(DateTime d) {
  final local = d.toLocal();
  final n = DateTime.now();
  if (local.year == n.year && local.month == n.month && local.day == n.day) return hora(local);
  return fechaCorta(local);
}

String dinero(num v, String moneda) {
  if (moneda == 'COP') {
    return '\$${NumberFormat.decimalPattern('es').format(v.round())} COP';
  }
  final decimals = v % 1 == 0 ? 0 : 2;
  return 'US\$${NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: decimals).format(v).trim()}';
}

String kg(double v) => '${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} kg';

String iniciales(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}
