import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../format.dart';
import '../models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, {this.status});
  @override
  String toString() => message;
}

/// Ciudades de respaldo si /api/ciudades no responde (mismo formato que el backend: sin tildes).
const ciudadesRespaldo = <String>['Bogota', 'Medellin', 'Cali', 'Cartagena', 'Barranquilla', 'Bucaramanga', 'Pereira', 'Miami', 'Madrid', 'Paris'];

/// Primero en el buscador cuando el campo está vacío.
const ciudadesPopulares = <String>['Bogota', 'Medellin', 'Cali', 'Miami', 'Madrid', 'Paris'];

/// Cliente del backend Lapticon (Render). Todas las peticiones autenticadas
/// llevan el Firebase ID token del usuario: el backend verifica la identidad.
class LapticonApi {
  LapticonApi._();
  static final instance = LapticonApi._();

  final _client = http.Client();
  List<String>? _ciudades;

  Future<Map<String, String>> _headers(bool auth) async {
    final h = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<dynamic> _send(String method, String path, {Object? body, bool auth = true}) async {
    final req = http.Request(method, Uri.parse('${AppConfig.apiBaseUrl}$path'))..headers.addAll(await _headers(auth));
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _client.send(req).timeout(AppConfig.requestTimeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder. Inténtalo de nuevo en un momento.');
    } catch (_) {
      throw ApiException('No hay conexión con el servidor. Revisa tu internet.');
    }

    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      final text = utf8.decode(res.bodyBytes, allowMalformed: true);
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = text;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(_messageFrom(data) ?? _defaultMessage(res.statusCode), status: res.statusCode);
  }

  static String? _messageFrom(dynamic d) {
    if (d is Map) {
      for (final k in ['message', 'mensaje', 'error', 'msg']) {
        final v = d[k];
        if (v is String && v.trim().isNotEmpty) return v;
        if (v is Map && v['message'] is String) return v['message'] as String;
      }
    }
    if (d is String && d.trim().isNotEmpty && d.length < 200 && !d.contains('<')) return d;
    return null;
  }

  static String _defaultMessage(int status) {
    switch (status) {
      case 400:
        return 'Los datos enviados no son válidos.';
      case 401:
        return 'Tu sesión expiró. Vuelve a iniciar sesión.';
      case 403:
        return 'No tienes permiso para esta acción.';
      case 404:
        return 'No se encontró lo que buscas.';
      case 429:
        return 'Demasiadas peticiones. Espera un momento.';
      default:
        return status >= 500 ? 'El servidor tuvo un problema ($status). Inténtalo más tarde.' : 'Error $status';
    }
  }

  /// Extrae una lista aunque el backend la envuelva en {data: [...]} u otra clave.
  static List<Map<String, dynamic>> _list(dynamic d) {
    if (d is List) return d.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    if (d is Map) {
      for (final k in ['data', 'items', 'results', 'viajes', 'encomiendas']) {
        if (d[k] is List) return _list(d[k]);
      }
    }
    return const [];
  }

  /// Extrae un objeto aunque venga envuelto en {data: {...}} u otra clave.
  static Map<String, dynamic>? _obj(dynamic d) {
    if (d is! Map) return null;
    final m = Map<String, dynamic>.from(d);
    for (final k in ['data', 'viaje', 'encomienda', 'usuario', 'user']) {
      if (m[k] is Map) return Map<String, dynamic>.from(m[k] as Map);
    }
    return m;
  }

  static String? _id(Map<String, dynamic>? o) => (o?['_id'] ?? o?['id'])?.toString();

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw ApiException('Inicia sesión primero.', status: 401);
    return u.uid;
  }

  // ------------------------------------------------------------- usuarios
  Future<void> registrarPerfil({required String nombre, required String apellido, required String telefono, required String nacionalidad}) async {
    await _send('POST', '/api/users/register', body: {
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'nacionalidad': nacionalidad,
    });
  }

  Future<void> actualizarPerfil(Map<String, String> campos) async {
    await _send('PUT', '/api/users/$_uid', body: campos);
  }

  /// null si el usuario aún no registró su perfil en el backend.
  Future<Map<String, dynamic>?> miPerfil() async {
    try {
      return _obj(await _send('GET', '/api/users/$_uid'));
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  // ------------------------------------------------------------- ciudades
  Future<List<String>> ciudades() async {
    if (_ciudades != null) return _ciudades!;
    try {
      final d = await _send('GET', '/api/ciudades/ciudades', auth: false);
      final raw = d is List ? d : (d is Map && d['data'] is List ? d['data'] as List : const []);
      final list = raw.map((e) => e is Map ? (e['nombre'] ?? e['name'] ?? '').toString() : e.toString()).where((s) => s.trim().isNotEmpty).toSet().toList()
        ..sort();
      if (list.isEmpty) return ciudadesRespaldo;
      _ciudades = list;
      return list;
    } catch (_) {
      return ciudadesRespaldo;
    }
  }

  // ------------------------------------------------------------- viajes
  Future<Viaje> crearViaje({required String numeroVuelo, required String ciudadOrigen, required String ciudadDestino, required DateTime fecha}) async {
    final body = {
      'numeroVuelo': numeroVuelo,
      'ciudadOrigen': ciudadOrigen,
      'ciudadDestino': ciudadDestino,
      'fechaViaje': ymd(fecha),
    };
    final o = _obj(await _send('POST', '/api/viajes', body: body));
    if (o != null && o['ciudadOrigen'] != null) return Viaje.fromJson(o);
    return Viaje(id: _id(o) ?? '', numeroVuelo: numeroVuelo, ciudadOrigen: ciudadOrigen, ciudadDestino: ciudadDestino, fecha: dia(fecha), estado: 'disponible');
  }

  /// El backend permite un viaje activo ("disponible") a la vez. null si no hay.
  Future<Viaje?> miViajeDisponible() async {
    try {
      final d = await _send('GET', '/api/viajes/disponible');
      final o = d is List ? (_list(d).isEmpty ? null : _list(d).first) : _obj(d);
      if (o == null || o['ciudadOrigen'] == null) return null;
      return Viaje.fromJson(o);
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  // ------------------------------------------------------------- encomiendas
  /// Crea la encomienda en el backend y devuelve su _id.
  /// Se envían también los campos extra por si el modelo del backend los admite.
  Future<String> crearEncomienda({
    required String ciudadOrigen,
    required String ciudadDestino,
    required String observaciones,
    required String moneda,
    required double valor,
    Map<String, dynamic> extra = const {},
  }) async {
    final o = _obj(await _send('POST', '/api/encomiendas', body: {
      'ciudadOrigen': ciudadOrigen,
      'ciudadDestino': ciudadDestino,
      'observaciones': observaciones,
      'moneda': moneda,
      'valor': valor,
      ...extra,
    }));
    final id = _id(o);
    if (id == null || id.isEmpty) throw ApiException('El servidor no devolvió el identificador de la encomienda.');
    return id;
  }

  /// IDs de encomiendas disponibles en una ruta, según el backend.
  Future<List<String>> encomiendasDisponiblesIds(String origen, String destino) async {
    final q = 'origen=${Uri.encodeQueryComponent(origen)}&destino=${Uri.encodeQueryComponent(destino)}';
    final d = await _send('GET', '/api/encomiendas/disponibles?$q');
    return _list(d).map(_id).whereType<String>().where((s) => s.isNotEmpty).toList();
  }

  Future<void> cancelarEncomienda(String id) async {
    await _send('PUT', '/api/encomiendas/$id/estado', body: {'estado': 'cancelada'});
  }
}
