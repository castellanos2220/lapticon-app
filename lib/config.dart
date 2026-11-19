/// Configuración de Lapticon.
///
/// Se puede cambiar al compilar, sin tocar el código:
///   flutter build apk --dart-define=API_URL=https://otro-backend.com
class AppConfig {
  /// Backend Lapticon (Render). Recibe el Firebase ID token como Bearer.
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://lapticon-backend.onrender.com',
  );

  /// Base de Firestore donde viven encargos, matches y chats.
  /// '(default)' es la base gratuita del proyecto. Una base con nombre
  /// (p. ej. --dart-define=FIRESTORE_DB=lapticon) aísla los datos, pero
  /// Google exige activar facturación para crearla.
  static const firestoreDatabaseId = String.fromEnvironment(
    'FIRESTORE_DB',
    defaultValue: '(default)',
  );

  /// Render (plan gratuito) "duerme" el servidor: la primera petición puede tardar ~1 min.
  static const requestTimeout = Duration(seconds: 75);
}
