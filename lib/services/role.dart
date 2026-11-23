import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cómo usa la app la persona: enviando encargos o llevándolos en su vuelo.
/// Una misma cuenta puede cambiar de rol desde Perfil.
enum AppRole {
  remitente('Remitente', 'Quiero enviar algo', 'Publica tu encargo y elige al viajero que lo lleva.', Icons.inventory_2_rounded),
  viajero('Viajero', 'Tengo un vuelo', 'Lleva encargos en tu ruta y gana dinero con tu viaje.', Icons.flight_takeoff_rounded);

  const AppRole(this.label, this.tagline, this.description, this.icon);
  final String label;
  final String tagline;
  final String description;
  final IconData icon;

  AppRole get otro => this == AppRole.remitente ? AppRole.viajero : AppRole.remitente;
}

/// Rol activo, guardado en el teléfono para que se recuerde entre aperturas.
class RoleController extends ValueNotifier<AppRole?> {
  RoleController._() : super(null);
  static final instance = RoleController._();

  static const _key = 'lapticon.role';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      value = AppRole.values.where((r) => r.name == name).firstOrNull;
    } catch (_) {
      value = null;
    }
  }

  Future<void> set(AppRole role) async {
    value = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, role.name);
    } catch (_) {
      // Si no se puede guardar, el rol vale para esta sesión.
    }
  }
}
