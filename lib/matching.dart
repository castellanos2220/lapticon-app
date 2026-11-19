import 'format.dart';
import 'models.dart';

/// Resultado de comparar el vuelo de un viajero con un encargo.
class Compatibilidad {
  final bool compatible;
  final List<String> razones; // por qué coincide
  final List<String> bloqueos; // por qué no
  final int? margenDias; // días entre el vuelo y la fecha límite

  const Compatibilidad({required this.compatible, required this.razones, required this.bloqueos, this.margenDias});
}

/// Un encargo solo se muestra a un viajero si:
///  - la ciudad de origen y la de destino coinciden (sin importar tildes ni mayúsculas);
///  - el vuelo es hoy o después, y no después de la fecha límite del encargo;
///  - el encargo sigue buscando viajero y no es del propio viajero.
Compatibilidad evaluarCompatibilidad({
  required Viaje viaje,
  required Encargo encargo,
  String? miUid,
  DateTime? hoy,
}) {
  final h = hoy ?? hoyDia();
  final razones = <String>[];
  final bloqueos = <String>[];

  if (miUid != null && encargo.senderId == miUid) bloqueos.add('Es tu propio encargo.');
  if (!encargo.abierto) bloqueos.add('El encargo ya no está disponible.');

  final mismoOrigen = normalizeCity(viaje.ciudadOrigen) == normalizeCity(encargo.ciudadOrigen);
  final mismoDestino = normalizeCity(viaje.ciudadDestino) == normalizeCity(encargo.ciudadDestino);
  if (mismoOrigen && mismoDestino) {
    razones.add('Misma ruta: ${encargo.ciudadOrigen} → ${encargo.ciudadDestino}.');
  } else {
    if (!mismoOrigen) bloqueos.add('Tu vuelo sale de otra ciudad.');
    if (!mismoDestino) bloqueos.add('Tu vuelo llega a otra ciudad.');
  }

  int? margen;
  final f = viaje.fecha;
  if (f == null) {
    bloqueos.add('Tu vuelo no tiene fecha registrada.');
  } else {
    if (f.isBefore(h)) bloqueos.add('Tu vuelo ya pasó.');
    margen = encargo.fechaLimite.difference(f).inDays;
    if (margen < 0) {
      bloqueos.add('Tu vuelo es después de la fecha límite (${fechaCorta(encargo.fechaLimite)}).');
    } else if (margen == 0) {
      razones.add('Vuelas el mismo día del límite de entrega.');
    } else {
      razones.add('Vuelas $margen ${margen == 1 ? 'día' : 'días'} antes del límite de entrega.');
    }
  }

  return Compatibilidad(compatible: bloqueos.isEmpty, razones: razones, bloqueos: bloqueos, margenDias: margen);
}
