import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config.dart';
import '../format.dart';
import '../models.dart';

/// Acceso a Firestore: datos extra de encargos, matches y mensajes del chat.
/// Las reglas (firebase/firestore.rules) validan cada escritura en el servidor.
class LapticonStore {
  LapticonStore._();
  static final instance = LapticonStore._();

  late final FirebaseFirestore _db = AppConfig.firestoreDatabaseId == '(default)'
      ? FirebaseFirestore.instance
      : FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: AppConfig.firestoreDatabaseId);

  CollectionReference<Map<String, dynamic>> get _encargos => _db.collection('encargos');
  CollectionReference<Map<String, dynamic>> get _matches => _db.collection('matches');

  User get _user {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw StateError('Sin sesión');
    return u;
  }

  String get uid => _user.uid;

  String get miNombre {
    final u = FirebaseAuth.instance.currentUser;
    final n = u?.displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final email = u?.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Usuario';
  }

  // ------------------------------------------------------------- encargos
  Future<void> crearEncargo(Encargo e) => _encargos.doc(e.id).set(e.toCreateMap());

  Stream<List<Encargo>> misEncargos() => _encargos
      .where('senderId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Encargo.fromDoc).toList());

  Stream<Encargo?> encargo(String id) => _encargos.doc(id).snapshots().map((s) => s.exists ? Encargo.fromDoc(s) : null);

  Future<Encargo?> encargoUnaVez(String id) async {
    final s = await _encargos.doc(id).get();
    return s.exists ? Encargo.fromDoc(s) : null;
  }

  /// Lee encargos por id (Firestore admite hasta 30 ids por consulta; se usan bloques de 10).
  Future<List<Encargo>> encargosPorIds(List<String> ids) async {
    final unique = ids.toSet().toList();
    final out = <Encargo>[];
    for (var i = 0; i < unique.length; i += 10) {
      final chunk = unique.sublist(i, i + 10 > unique.length ? unique.length : i + 10);
      final s = await _encargos.where(FieldPath.documentId, whereIn: chunk).get();
      out.addAll(s.docs.map(Encargo.fromDoc));
    }
    return out;
  }

  /// IDs de encargos abiertos en una ruta (complementa la búsqueda del backend).
  Future<List<String>> encargoIdsPorRuta(String origen, String destino) async {
    final s = await _encargos
        .where('origenKey', isEqualTo: normalizeCity(origen))
        .where('destinoKey', isEqualTo: normalizeCity(destino))
        .where('estado', isEqualTo: 'publicado')
        .limit(100)
        .get();
    return s.docs.map((d) => d.id).toList();
  }

  /// Cancela el encargo y descarta a los viajeros interesados.
  Future<void> cancelarEncargo(Encargo e, List<MatchDoc> interesados) async {
    final batch = _db.batch();
    batch.update(_encargos.doc(e.id), {'estado': 'cancelado', 'updatedAt': FieldValue.serverTimestamp()});
    for (final m in interesados.where((m) => m.pendiente)) {
      batch.update(_matches.doc(m.id), {'estado': 'rechazado', 'updatedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Future<void> marcarEntregado(Encargo e) =>
      _encargos.doc(e.id).update({'estado': 'entregado', 'updatedAt': FieldValue.serverTimestamp()});

  // ------------------------------------------------------------- matches
  /// Todos los matches donde participo (como remitente o viajero), más recientes primero.
  Stream<List<MatchDoc>> misMatches() => _matches
      .where('participants', arrayContains: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(MatchDoc.fromDoc).toList());

  static String matchIdFor(String encargoId, String travelerId) => '${encargoId}_$travelerId';

  /// El viajero muestra interés en llevar el encargo. El id determinista evita duplicados.
  Future<void> meInteresa(Encargo e, Viaje v) {
    final me = uid;
    return _matches.doc(matchIdFor(e.id, me)).set({
      'encargoId': e.id,
      'senderId': e.senderId,
      'senderName': e.senderName,
      'travelerId': me,
      'travelerName': miNombre,
      'participants': [e.senderId, me],
      'viajeId': v.id,
      'numeroVuelo': v.numeroVuelo,
      'fechaViaje': v.fecha == null ? null : ymd(v.fecha!),
      'ciudadOrigen': e.ciudadOrigen,
      'ciudadDestino': e.ciudadDestino,
      'precio': e.precio,
      'moneda': e.moneda,
      'descripcion': e.descripcion,
      'estado': 'interesado',
      'readAt': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> retirarInteres(MatchDoc m) =>
      _matches.doc(m.id).update({'estado': 'retirado', 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> rechazar(MatchDoc m) =>
      _matches.doc(m.id).update({'estado': 'rechazado', 'updatedAt': FieldValue.serverTimestamp()});

  /// El remitente acepta a un viajero: match + encargo asignado en una sola
  /// transacción (nadie más puede ser aceptado), y descarta al resto.
  Future<void> aceptar(MatchDoc m, List<MatchDoc> otrosInteresados) async {
    final encargoRef = _encargos.doc(m.encargoId);
    final matchRef = _matches.doc(m.id);
    await _db.runTransaction((tx) async {
      final e = await tx.get(encargoRef);
      final mm = await tx.get(matchRef);
      if (!e.exists || e.data()?['estado'] != 'publicado') {
        throw StateError('Este encargo ya tiene un viajero asignado o no está disponible.');
      }
      if (!mm.exists || mm.data()?['estado'] != 'interesado') {
        throw StateError('El viajero ya no está disponible para este encargo.');
      }
      tx.update(matchRef, {'estado': 'match', 'updatedAt': FieldValue.serverTimestamp()});
      tx.update(encargoRef, {
        'estado': 'asignado',
        'matchId': m.id,
        'travelerId': m.travelerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    final pendientes = otrosInteresados.where((o) => o.id != m.id && o.pendiente).toList();
    if (pendientes.isNotEmpty) {
      final batch = _db.batch();
      for (final o in pendientes) {
        batch.update(_matches.doc(o.id), {'estado': 'rechazado', 'updatedAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
  }

  // ------------------------------------------------------------- chat
  Stream<List<Mensaje>> mensajes(String matchId) => _matches
      .doc(matchId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(300)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(Mensaje.fromDoc).toList());

  /// Mensaje + resumen en el match, en un lote atómico.
  Future<void> enviarMensaje(MatchDoc m, String text) {
    final batch = _db.batch();
    final msgRef = _matches.doc(m.id).collection('messages').doc();
    batch.set(msgRef, {'senderId': uid, 'text': text, 'createdAt': FieldValue.serverTimestamp()});
    batch.update(_matches.doc(m.id), {
      'lastMessage': text.length > 120 ? '${text.substring(0, 117)}…' : text,
      'lastSenderId': uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Future<void> marcarLeido(MatchDoc m) => _matches.doc(m.id).update({'readAt.$uid': FieldValue.serverTimestamp()});
}
