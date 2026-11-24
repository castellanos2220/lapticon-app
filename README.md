# Lapticon — app Android (Flutter)

App que sirve para enviar encargos con viajeros que ya tienen un vuelo en la misma ruta.

- **Roles:** al iniciar sesión o crear la cuenta se elige **Remitente** o **Viajero**. La app muestra solo las pestañas de ese rol (Envíos o Viajar, más Chats y Perfil). El rol se recuerda en el teléfono y se cambia desde *Perfil*.
- **Envíos (remitente):** asistente de 3 pasos.
  1. Ruta y fecha límite.
  2. Qué envías: categoría, descripción, tamaño y peso.
  3. El precio que pagas al viajero.
- **Viajar (viajero):** registra su vuelo y ve **solo** los encargos compatibles: misma ciudad de origen y destino, y vuelo entre hoy y la fecha límite.
- **Match:** el viajero toca *Me interesa* y el remitente lo acepta. Al aceptarlo se descarta al resto de interesados.
- **Chat:** se habilita únicamente con match. Funciona en tiempo real, con indicador de no leídos, separadores por día y sugerencias de primer mensaje.
- **Datos de ejemplo:** mientras no hay envíos, encargos o chats reales, la app muestra ejemplos marcados como **EJEMPLO** (`lib/demo.dart`). Nunca se guardan en Firestore ni en el backend, y desaparecen en cuanto hay datos reales.

## Arquitectura

| Pieza | Dónde vive |
|---|---|
| Cuentas | Firebase Authentication (proyecto `lapticon-eba31`) |
| Perfil, encomiendas, viajes, ciudades | Backend Lapticon en Render (`https://lapticon-backend.onrender.com`) |
| Datos extra del encargo, match y chat | Cloud Firestore, base `(default)` |

La app manda el *ID token* de Firebase como `Bearer` en cada petición al backend.

### Tecnologías

- Flutter (Dart `^3.8.0`), Material 3, interfaz en español (`flutter_localizations`, `intl`)
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `http` para el backend REST
- `shared_preferences` para recordar el rol elegido
- Tipografía Plus Jakarta Sans incluida en `assets/fonts` (licencia OFL), sin descargas en tiempo de ejecución
- Android: `applicationId = com.lapticon.app`, `minSdk 24`, Kotlin 2.3.0, NDK 27.0.12077973

---

## Compilar el proyecto.

### Requisitos

1. **Flutter** (canal estable) con `flutter\bin` en el PATH: https://docs.flutter.dev/get-started/install/windows/mobile
2. **Git** en el PATH. Flutter lo necesita para compilar.
3. **Android Studio** con el Android SDK y las *Android SDK Command-line Tools*.
4. Acepta las licencias y verifica:
   ```powershell
   flutter doctor --android-licenses
   flutter doctor
   ```

### Pasos

```powershell
git clone <github.com/castellanos2220/lapticon-app>
cd lapticon
flutter pub get
flutter test                 # pruebas de la lógica de compatibilidad
flutter run                  # celular por USB o emulador
flutter build apk --release
```

El APK queda en **`build\app\outputs\flutter-apk\app-release.apk`**. Para instalarlo, pásalo al celular; Android pedirá permitir apps de origen desconocido.

Para un APK más liviano, genera uno por arquitectura con `flutter build apk --release --split-per-abi` y usa `app-arm64-v8a-release.apk`.

> El APK de release se firma con la clave de depuración, que sirve para probar y compartir. Para publicarlo en Play Store hay que crear una clave propia: https://docs.flutter.dev/deployment/android#signing-the-app

### Variables de compilación (opcionales)

| Variable | Por defecto | Uso |
|---|---|---|
| `API_URL` | `https://lapticon-backend.onrender.com` | URL del backend |
| `FIRESTORE_DB` | `(default)` | Base de Firestore |

```powershell
flutter build apk --release --dart-define=API_URL=https://otro-backend.com
```

### Configuración de Android incluida

Ya viene aplicada en el repositorio, así que no hay que tocarla:

- `android/app/google-services.json`: configuración cliente de Firebase para `com.lapticon.app`.
- Plugin `com.google.gms.google-services` en `settings.gradle.kts` y `app/build.gradle.kts`.
- `minSdk = 24`, porque `firebase_auth` lo exige.
- Kotlin 2.3.0, porque el SDK nativo de Firebase Auth está compilado con metadatos de Kotlin 2.4.
- `ndkVersion = "27.0.12077973"`, la que requieren los plugins de Firebase.
- Permiso `INTERNET` en el `AndroidManifest.xml`. Sin él, el APK de release no se conecta.

---

## Firebase (una sola vez por proyecto)

En https://console.firebase.google.com, proyecto **lapticon-eba31**:

1. **Authentication → Método de acceso:** habilita **Correo electrónico/contraseña**.
2. **Firestore Database:** crea la base `(default)` en modo producción.
3. **Reglas e índices:**
   ```powershell
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore
   ```
   >  Esto **reemplaza** las reglas de la base `(default)`. Si otra app del proyecto ya usa Firestore, combina antes sus reglas con `firebase/firestore.rules`.

   La app **no necesita índices compuestos**: las listas de envíos y de matches se ordenan en el teléfono. Así se evita el error *"falta un índice"* (`failed-precondition`) aunque los índices no estén desplegados. `firestore.indexes.json` se conserva por si más adelante se ordena en el servidor.

---

## Cómo probar el flujo completo

Necesitas **dos cuentas**: dos celulares, o un celular y el emulador.

1. **Cuenta A (remitente):** Envíos → *Nuevo envío* → Bogota → Madrid, fecha límite en 2 semanas, "Documentos", tamaño pequeño, US$20 → *Publicar*.
2. **Cuenta B (viajero):** Viajar → *Registrar mi vuelo* → `AV010`, Bogota → Madrid, fecha en 1 semana. El encargo de A aparece en "Encargos para tu vuelo".
3. **B** abre el encargo y toca **Me interesa llevarlo**.
4. **A** ve el aviso en *Envíos* y *Chats*. Abre el envío y toca **Aceptar · hacer match**, y se abre el chat.
5. Ambos chatean en tiempo real. **A** marca el envío como entregado cuando llega.

Caso negativo: con un vuelo **después** de la fecha límite, o con otra ciudad de destino, el encargo **no aparece**.

---

## Estructura

```
lib/
├── main.dart                     inicio, Firebase, idioma español, sesión persistente
├── config.dart                   URL del backend y base de Firestore
├── theme.dart                    colores, tipografía y estilos
├── format.dart                   fechas, dinero, kg
├── models.dart                   Viaje, Encargo, MatchDoc, Mensaje
├── matching.dart                 reglas de compatibilidad vuelo ↔ encargo
├── demo.dart                     datos de ejemplo (solo se muestran, nunca se guardan)
├── services/
│   ├── api.dart                  backend Render (token de Firebase en cada petición)
│   ├── store.dart                Firestore: encargos, matches (transacción al aceptar), chat
│   ├── ofertas.dart              encargos compatibles con el vuelo del viajero
│   ├── matches_controller.dart   matches en tiempo real (contadores y chats)
│   └── role.dart                 rol activo (remitente / viajero), guardado en el teléfono
├── widgets/                      componentes reutilizables, cabeceras inmersivas, selector de rol, vistas de ejemplo
└── screens/                      bienvenida, login/registro, envíos, viajar, chat, perfil
firebase/firestore.rules          seguridad en el servidor (chat solo con match)
firebase/firestore.indexes.json   índices de Firestore
test/matching_test.dart           pruebas de la lógica de compatibilidad
```

### Seguridad (reglas de Firestore)

- Solo los dos participantes pueden leer un match y su chat.
- Escribir en el chat exige `estado == 'match'`. El autor del mensaje debe ser quien escribe y la hora la pone el servidor.
- Solo el remitente acepta, y aceptar exige asignar el encargo en la misma transacción. Así nunca hay dos viajeros asignados al mismo encargo.
- Nadie puede cambiar el precio, la ruta ni los participantes después de crearlos.

### Limitaciones conocidas

- **La compatibilidad la filtra la app.** El vuelo del viajero vive en el backend de Render, así que Firestore no puede comprobar en el servidor que el vuelo coincide. Para blindarlo hay que agregar al backend una ruta tipo `GET /api/encomiendas/compatibles`.
- El backend permite **un viaje activo a la vez**.
- Render (plan gratuito) se "duerme": la primera petición del día puede tardar hasta un minuto. La app lo avisa con un mensaje.
- Las notificaciones de push quedan para una fase siguiente. Dentro de la app, los contadores se actualizan en tiempo real.
