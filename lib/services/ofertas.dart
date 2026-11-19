import '../matching.dart';
import '../models.dart';
import 'api.dart';
import 'store.dart';

class Oferta {
  final Encargo encargo;
  final Compatibilidad compatibilidad;
  const Oferta(this.encargo, this.compatibilidad);
}

/// Encargos que el viajero puede ver para su vuelo.
///
/// Se unen dos fuentes (la búsqueda del backend Render y la de Firestore por ruta)
/// y luego se aplican las reglas de compatibilidad: misma ruta, vuelo entre hoy
/// y la fecha límite, encargo abierto y que no sea propio.
Future<List<Oferta>> buscarOfertas(Viaje viaje) async {
  final store = LapticonStore.instance;
  final ids = <String>{};
  Object? errorBackend;
  try {
    ids.addAll(await LapticonApi.instance.encomiendasDisponiblesIds(viaje.ciudadOrigen, viaje.ciudadDestino));
  } catch (e) {
    errorBackend = e;
  }
  ids.addAll(await store.encargoIdsPorRuta(viaje.ciudadOrigen, viaje.ciudadDestino));
  if (ids.isEmpty && errorBackend != null) throw errorBackend;

  final encargos = await store.encargosPorIds(ids.toList());
  final uid = store.uid;
  final ofertas = encargos
      .map((e) => Oferta(e, evaluarCompatibilidad(viaje: viaje, encargo: e, miUid: uid)))
      .where((o) => o.compatibilidad.compatible)
      .toList()
    ..sort((a, b) {
      final p = b.encargo.precio.compareTo(a.encargo.precio);
      return p != 0 ? p : a.encargo.fechaLimite.compareTo(b.encargo.fechaLimite);
    });
  return ofertas;
}
