import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'services/role.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // En Android, la configuración sale de android/app/google-services.json.
  await Firebase.initializeApp();
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';
  await RoleController.instance.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const LapticonApp());
}

class LapticonApp extends StatelessWidget {
  const LapticonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapticon',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// Muestra la bienvenida o la app según haya sesión (la sesión persiste entre aperturas).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.ink,
            body: Center(child: CircularProgressIndicator(color: AppColors.sky)),
          );
        }
        final user = snap.data;
        if (user == null) return const WelcomeScreen();
        return HomeShell(key: ValueKey(user.uid));
      },
    );
  }
}
