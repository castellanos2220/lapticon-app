// Dibuja pantallas y tarjetas en teléfonos angostos/bajos y con letra grande:
// falla si algún elemento se desborda.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lapticon/demo.dart';
import 'package:lapticon/format.dart';
import 'package:lapticon/matching.dart';
import 'package:lapticon/models.dart';
import 'package:lapticon/screens/auth_screens.dart';
import 'package:lapticon/screens/encargo_detail_screen.dart';
import 'package:lapticon/screens/envios_tab.dart';
import 'package:lapticon/screens/viajar_tab.dart';
import 'package:lapticon/screens/welcome_screen.dart';
import 'package:lapticon/services/ofertas.dart';
import 'package:lapticon/services/role.dart';
import 'package:lapticon/theme.dart';
import 'package:lapticon/widgets/demo_views.dart';
import 'package:lapticon/widgets/role_selector.dart';

Future<void> loadFonts() async {
  final l = FontLoader('PlusJakartaSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final b = File('assets/fonts/PlusJakartaSans-$w.ttf').readAsBytesSync();
    l.addFont(Future.value(ByteData.view(b.buffer)));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    await loadFonts();
    await initializeDateFormatting('es');
    Intl.defaultLocale = 'es';
  });
  final viaje = Viaje(
    id: 'v',
    numeroVuelo: 'AV 4211',
    ciudadOrigen: 'Bogota',
    ciudadDestino: 'Ciudad de Mexico',
    fecha: hoyDia().add(const Duration(days: 5)),
    estado: 'activo',
  );
  const comp = Compatibilidad(compatible: true, razones: ['Misma ruta'], bloqueos: [], margenDias: 3);

  final cases = <String, Widget Function()>{
    'welcome': () => const WelcomeScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'demo chat 0': () => DemoChatScreen(chat: demoChats[0]),
    'demo chat 1': () => DemoChatScreen(chat: demoChats[1]),
    'sheet remitente': () => Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showDemoEncargo(c, demoMisEnvios().first, comoViajero: false, accionLabel: 'Crear mi primer envío', onAccion: () {}),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
    'sheet viajero': () => Builder(
      builder: (c) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showDemoEncargo(c, demoMercado()[1], comoViajero: true, accionLabel: 'Registrar mi vuelo', onAccion: () {}),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
    'cards': () => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoleSelector(value: AppRole.remitente, onChanged: (_) {}),
          FlightTicket(viaje: viaje),
          for (final e in demoMisEnvios()) EncargoCard(encargo: e, interesados: demoInteresados(e.id), demo: true),
          for (final e in demoMercado()) OfertaCard(oferta: Oferta(e, comp), viaje: null, onChanged: () {}, demo: true),
          for (final e in demoMercado()) EncargoResumen(encargo: e),
        ],
      ),
    ),
  };

  for (final w in [320.0, 360.0, 411.0]) {
    for (final h in [640.0, 780.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final c in cases.entries) {
          testWidgets('${c.key} @${w.toInt()}x${h.toInt()} x$scale', (t) async {
            t.view.physicalSize = Size(w * 3, h * 3);
            t.view.devicePixelRatio = 3;
            addTearDown(t.view.reset);
            await t.pumpWidget(
              MaterialApp(
                theme: buildTheme(),
                home: MediaQuery.withClampedTextScaling(minScaleFactor: scale, maxScaleFactor: scale, child: c.value()),
              ),
            );
            await t.pump(const Duration(milliseconds: 1500));
            if (c.key.startsWith('sheet')) {
              await t.tap(find.text('abrir'));
              await t.pumpAndSettle();
            }
            if (c.key == 'cards') {
              for (var i = 0; i < 30; i++) {
                await t.drag(find.byType(ListView), const Offset(0, -400));
                await t.pump();
              }
            }
          });
        }
      }
    }
  }
}
