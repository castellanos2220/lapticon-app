import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models.dart';
import 'store.dart';

/// Mantiene en memoria los matches del usuario (una sola suscripción a Firestore)
/// para el contador de no leídos, la lista de chats y los detalles de encargos.
class MatchesController extends ChangeNotifier {
  MatchesController._();
  static final instance = MatchesController._();

  StreamSubscription<List<MatchDoc>>? _sub;
  List<MatchDoc> items = const [];
  Object? error;
  bool loading = true;
  Object? _owner;

  /// [owner] identifica a quien abrió la suscripción (la pantalla principal).
  /// Así, si se reemplaza por otra (cambio de usuario), el dispose de la vieja no
  /// cancela la suscripción nueva.
  void start(Object owner) {
    _owner = owner;
    _sub?.cancel();
    items = const [];
    error = null;
    loading = true;
    _sub = LapticonStore.instance.misMatches().listen(
      (list) {
        items = list;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        error = e;
        loading = false;
        notifyListeners();
      },
    );
  }

  void stop(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _sub?.cancel();
    _sub = null;
    items = const [];
    loading = true;
  }

  /// Reintenta la suscripción tras un error, conservando al dueño actual.
  void retry() {
    final owner = _owner;
    if (owner != null) start(owner);
  }

  MatchDoc? byId(String? id) {
    if (id == null) return null;
    for (final m in items) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<MatchDoc> deEncargo(String encargoId) => items.where((m) => m.encargoId == encargoId).toList();

  MatchDoc? miInteresEn(String encargoId, String uid) => byId(LapticonStore.matchIdFor(encargoId, uid));

  int noLeidos(String uid) => items.where((m) => m.noLeidoPara(uid)).length;

  /// Solicitudes nuevas que esperan respuesta del remitente.
  int pendientesComoRemitente(String uid) => items.where((m) => m.pendiente && m.senderId == uid).length;
}
