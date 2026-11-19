// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../lib/matching.dart';
import '../lib/models.dart';

Viaje vuelo({String o = 'Bogota', String d = 'Madrid', DateTime? fecha}) => Viaje(
      id: 'v1',
      numeroVuelo: 'AV010',
      ciudadOrigen: o,
      ciudadDestino: d,
      fecha: fecha ?? DateTime.utc(2030, 1, 10),
      estado: 'disponible',
    );

Encargo encargo({String o = 'Bogota', String d = 'Madrid', DateTime? limite, String estado = 'publicado', String sender = 'ana'}) => Encargo(
      id: 'e1',
      senderId: sender,
      senderName: 'Ana',
      ciudadOrigen: o,
      ciudadDestino: d,
      fechaLimite: limite ?? DateTime.utc(2030, 1, 20),
      descripcion: 'Documentos',
      categoria: 'documentos',
      tamano: Tamano.pequeno,
      pesoKg: 1,
      precio: 20,
      moneda: 'USD',
      estado: estado,
    );

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  final hoy = DateTime.utc(2030, 1, 1);

  test('normalizeCity ignora tildes, mayúsculas y espacios', () {
    expect(normalizeCity('  Bogotá '), 'bogota');
    expect(normalizeCity('MEDELLÍN'), 'medellin');
    expect(normalizeCity('São  Paulo'), 'sao paulo');
  });

  test('parseDay acepta YYYY-MM-DD e ISO completo', () {
    expect(parseDay('2030-01-10'), DateTime.utc(2030, 1, 10));
    expect(parseDay('2030-01-10T00:00:00.000Z'), DateTime.utc(2030, 1, 10));
    expect(parseDay(null), isNull);
    expect(parseDay('no es fecha'), isNull);
  });

  test('misma ruta y vuelo antes del límite → compatible, con margen', () {
    final c = evaluarCompatibilidad(viaje: vuelo(), encargo: encargo(), miUid: 'tomas', hoy: hoy);
    expect(c.compatible, isTrue);
    expect(c.margenDias, 10);
    expect(c.razones, isNotEmpty);
  });

  test('la ruta coincide aunque el backend y el usuario escriban distinto', () {
    final c = evaluarCompatibilidad(viaje: vuelo(o: 'bogotá'), encargo: encargo(o: 'Bogota'), miUid: 'tomas', hoy: hoy);
    expect(c.compatible, isTrue);
  });

  test('vuelo el mismo día del límite → compatible con margen 0', () {
    final c = evaluarCompatibilidad(viaje: vuelo(fecha: DateTime.utc(2030, 1, 20)), encargo: encargo(), miUid: 'tomas', hoy: hoy);
    expect(c.compatible, isTrue);
    expect(c.margenDias, 0);
  });

  final noCompatibles = <String, Compatibilidad Function()>{
    'otra ciudad de origen': () => evaluarCompatibilidad(viaje: vuelo(o: 'Cali'), encargo: encargo(), miUid: 'tomas', hoy: hoy),
    'otra ciudad de destino': () => evaluarCompatibilidad(viaje: vuelo(d: 'Paris'), encargo: encargo(), miUid: 'tomas', hoy: hoy),
    'vuelo después del límite': () => evaluarCompatibilidad(viaje: vuelo(fecha: DateTime.utc(2030, 1, 21)), encargo: encargo(), miUid: 'tomas', hoy: hoy),
    'vuelo ya pasó': () => evaluarCompatibilidad(viaje: vuelo(fecha: DateTime.utc(2029, 12, 31)), encargo: encargo(), miUid: 'tomas', hoy: hoy),
    'encargo ya asignado': () => evaluarCompatibilidad(viaje: vuelo(), encargo: encargo(estado: 'asignado'), miUid: 'tomas', hoy: hoy),
    'encargo cancelado': () => evaluarCompatibilidad(viaje: vuelo(), encargo: encargo(estado: 'cancelado'), miUid: 'tomas', hoy: hoy),
    'encargo propio': () => evaluarCompatibilidad(viaje: vuelo(), encargo: encargo(sender: 'tomas'), miUid: 'tomas', hoy: hoy),
    'vuelo sin fecha': () => evaluarCompatibilidad(
          viaje: const Viaje(id: 'v', numeroVuelo: 'AV1', ciudadOrigen: 'Bogota', ciudadDestino: 'Madrid', fecha: null, estado: 'disponible'),
          encargo: encargo(),
          miUid: 'tomas',
          hoy: hoy,
        ),
  };
  noCompatibles.forEach((nombre, evaluar) {
    test('no compatible: $nombre', () {
      final c = evaluar();
      expect(c.compatible, isFalse);
      expect(c.bloqueos, isNotEmpty);
    });
  });

  test('Viaje.fromJson tolera respuestas del backend con _id e ISO', () {
    final v = Viaje.fromJson({'_id': 'abc', 'numeroVuelo': 'AA123', 'ciudadOrigen': 'Bogota', 'ciudadDestino': 'Miami', 'fechaViaje': '2026-12-01T00:00:00.000Z'});
    expect(v.id, 'abc');
    expect(v.fecha, DateTime.utc(2026, 12, 1));
  });
}
