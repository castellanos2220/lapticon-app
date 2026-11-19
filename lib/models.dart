import 'package:cloud_firestore/cloud_firestore.dart';

import 'format.dart';

/// Minúsculas, sin tildes y sin espacios repetidos: "Bogotá " == "bogota".
String normalizeCity(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = s.trim().toLowerCase();
  final b = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Acepta 'YYYY-MM-DD', ISO completo, Timestamp o DateTime. Devuelve el día en UTC.
DateTime? parseDay(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return dia(v.toDate());
  if (v is DateTime) return dia(v);
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(v.toString());
  if (m == null) return null;
  return DateTime.utc(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
}

DateTime? _ts(dynamic v, {DateTime? whenPending}) {
  if (v is Timestamp) return v.toDate();
  if (v == null) return whenPending;
  return null;
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

// ---------------------------------------------------------------------------
// Viaje (backend Render)
// ---------------------------------------------------------------------------

class Viaje {
  final String id;
  final String numeroVuelo;
  final String ciudadOrigen;
  final String ciudadDestino;
  final DateTime? fecha;
  final String estado;

  const Viaje({
    required this.id,
    required this.numeroVuelo,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.fecha,
    required this.estado,
  });

  factory Viaje.fromJson(Map<String, dynamic> j) => Viaje(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        numeroVuelo: (j['numeroVuelo'] ?? j['vuelo'] ?? '').toString(),
        ciudadOrigen: (j['ciudadOrigen'] ?? j['origen'] ?? '').toString(),
        ciudadDestino: (j['ciudadDestino'] ?? j['destino'] ?? '').toString(),
        fecha: parseDay(j['fechaViaje'] ?? j['fecha']),
        estado: (j['estado'] ?? 'disponible').toString(),
      );
}

// ---------------------------------------------------------------------------
// Encargo: encomienda creada en Render + datos extra en Firestore (encargos/{idRender})
// ---------------------------------------------------------------------------

enum Tamano {
  pequeno('S', 'Pequeño', 'Sobre o bolsa', 2),
  mediano('M', 'Mediano', 'Caja de zapatos', 8),
  grande('L', 'Grande', 'Maleta de mano', 23);

  const Tamano(this.code, this.label, this.hint, this.maxKg);
  final String code;
  final String label;
  final String hint;
  final double maxKg;

  static Tamano fromCode(String? c) => Tamano.values.firstWhere((t) => t.code == c, orElse: () => Tamano.pequeno);
}

const categorias = <String, String>{
  'documentos': 'Documentos',
  'ropa': 'Ropa y calzado',
  'electronicos': 'Electrónicos',
  'cosmeticos': 'Cosméticos',
  'libros': 'Libros',
  'regalos': 'Regalos',
  'otro': 'Otro',
};

const estadosEncargo = <String, String>{
  'publicado': 'Buscando viajero',
  'asignado': 'Viajero asignado',
  'entregado': 'Entregado',
  'cancelado': 'Cancelado',
};

class Encargo {
  final String id; // _id de la encomienda en Render
  final String senderId;
  final String senderName;
  final String ciudadOrigen;
  final String ciudadDestino;
  final DateTime fechaLimite;
  final String descripcion;
  final String categoria;
  final Tamano tamano;
  final double pesoKg;
  final double precio;
  final String moneda;
  final String estado;
  final String? matchId;
  final String? travelerId;
  final DateTime? createdAt;

  const Encargo({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.fechaLimite,
    required this.descripcion,
    required this.categoria,
    required this.tamano,
    required this.pesoKg,
    required this.precio,
    required this.moneda,
    this.estado = 'publicado',
    this.matchId,
    this.travelerId,
    this.createdAt,
  });

  bool get abierto => estado == 'publicado';
  String get categoriaLabel => categorias[categoria] ?? 'Otro';
  String get estadoLabel => estadosEncargo[estado] ?? estado;

  factory Encargo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? const <String, dynamic>{};
    return Encargo(
      id: d.id,
      senderId: (j['senderId'] ?? '').toString(),
      senderName: (j['senderName'] ?? 'Remitente').toString(),
      ciudadOrigen: (j['ciudadOrigen'] ?? '').toString(),
      ciudadDestino: (j['ciudadDestino'] ?? '').toString(),
      fechaLimite: parseDay(j['fechaLimite']) ?? DateTime.utc(2000),
      descripcion: (j['descripcion'] ?? '').toString(),
      categoria: (j['categoria'] ?? 'otro').toString(),
      tamano: Tamano.fromCode(j['tamano'] as String?),
      pesoKg: _num(j['pesoKg']),
      precio: _num(j['precio']),
      moneda: (j['moneda'] ?? 'USD').toString(),
      estado: (j['estado'] ?? 'publicado').toString(),
      matchId: j['matchId'] as String?,
      travelerId: j['travelerId'] as String?,
      createdAt: _ts(j['createdAt'], whenPending: DateTime.now()),
    );
  }

  Map<String, dynamic> toCreateMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'ciudadOrigen': ciudadOrigen,
        'ciudadDestino': ciudadDestino,
        'origenKey': normalizeCity(ciudadOrigen),
        'destinoKey': normalizeCity(ciudadDestino),
        'fechaLimite': ymd(fechaLimite),
        'descripcion': descripcion,
        'categoria': categoria,
        'tamano': tamano.code,
        'pesoKg': pesoKg,
        'precio': precio,
        'moneda': moneda,
        'estado': 'publicado',
        'matchId': null,
        'travelerId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

// ---------------------------------------------------------------------------
// Match: interés de un viajero en un encargo. Al aceptarlo el remitente,
// estado = 'match' y se habilita el chat (subcolección messages).
// ---------------------------------------------------------------------------

const estadosMatch = <String, String>{
  'interesado': 'Esperando respuesta',
  'match': 'Match',
  'rechazado': 'No seleccionado',
  'retirado': 'Retirado',
};

class MatchDoc {
  final String id; // {encargoId}_{travelerId}
  final String encargoId;
  final String senderId;
  final String senderName;
  final String travelerId;
  final String travelerName;
  final String viajeId;
  final String numeroVuelo;
  final DateTime? fechaViaje;
  final String ciudadOrigen;
  final String ciudadDestino;
  final double precio;
  final String moneda;
  final String descripcion;
  final String estado;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;
  final Map<String, DateTime> readAt;

  const MatchDoc({
    required this.id,
    required this.encargoId,
    required this.senderId,
    required this.senderName,
    required this.travelerId,
    required this.travelerName,
    required this.viajeId,
    required this.numeroVuelo,
    required this.fechaViaje,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.precio,
    required this.moneda,
    required this.descripcion,
    required this.estado,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.updatedAt,
    this.readAt = const {},
  });

  bool get esMatch => estado == 'match';
  bool get pendiente => estado == 'interesado';
  bool soyRemitente(String uid) => uid == senderId;
  String otroNombre(String uid) => uid == senderId ? travelerName : senderName;

  bool noLeidoPara(String uid) {
    if (!esMatch || lastMessageAt == null || lastSenderId == null || lastSenderId == uid) return false;
    final r = readAt[uid];
    return r == null || r.isBefore(lastMessageAt!);
  }

  factory MatchDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? const <String, dynamic>{};
    final rawRead = j['readAt'];
    final read = <String, DateTime>{};
    if (rawRead is Map) {
      rawRead.forEach((k, v) {
        // null = escritura pendiente de serverTimestamp → se acaba de marcar como leído.
        final t = _ts(v, whenPending: DateTime.now());
        if (t != null) read[k.toString()] = t;
      });
    }
    return MatchDoc(
      id: d.id,
      encargoId: (j['encargoId'] ?? '').toString(),
      senderId: (j['senderId'] ?? '').toString(),
      senderName: (j['senderName'] ?? 'Remitente').toString(),
      travelerId: (j['travelerId'] ?? '').toString(),
      travelerName: (j['travelerName'] ?? 'Viajero').toString(),
      viajeId: (j['viajeId'] ?? '').toString(),
      numeroVuelo: (j['numeroVuelo'] ?? '').toString(),
      fechaViaje: parseDay(j['fechaViaje']),
      ciudadOrigen: (j['ciudadOrigen'] ?? '').toString(),
      ciudadDestino: (j['ciudadDestino'] ?? '').toString(),
      precio: _num(j['precio']),
      moneda: (j['moneda'] ?? 'USD').toString(),
      descripcion: (j['descripcion'] ?? '').toString(),
      estado: (j['estado'] ?? 'interesado').toString(),
      lastMessage: j['lastMessage'] as String?,
      lastSenderId: j['lastSenderId'] as String?,
      lastMessageAt: j.containsKey('lastMessageAt') ? _ts(j['lastMessageAt'], whenPending: DateTime.now()) : null,
      updatedAt: _ts(j['updatedAt'], whenPending: DateTime.now()),
      readAt: read,
    );
  }
}

class Mensaje {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt; // null mientras el servidor no confirma
  final bool pendiente;

  const Mensaje({required this.id, required this.senderId, required this.text, this.createdAt, this.pendiente = false});

  factory Mensaje.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? const <String, dynamic>{};
    final ts = j['createdAt'];
    return Mensaje(
      id: d.id,
      senderId: (j['senderId'] ?? '').toString(),
      text: (j['text'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
      pendiente: d.metadata.hasPendingWrites,
    );
  }
}
