import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/matches_controller.dart';
import '../services/role.dart';
import '../theme.dart';
import '../widgets/immersive.dart';
import '../widgets/role_selector.dart';
import 'chats_tab.dart';
import 'envios_tab.dart';
import 'perfil_tab.dart';
import 'viajar_tab.dart';
import 'welcome_screen.dart';

/// Navegación principal según el rol:
///   Remitente: Envíos · Chats · Perfil
///   Viajero:   Viajar · Chats · Perfil
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _matches = MatchesController.instance;
  final _role = RoleController.instance;
  AppRole? _lastRole;

  @override
  void initState() {
    super.initState();
    _matches.start(this);
  }

  @override
  void dispose() {
    _matches.stop(this);
    super.dispose();
  }

  void _goTo(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return ValueListenableBuilder<AppRole?>(
      valueListenable: _role,
      builder: (context, role, _) {
        if (role == null) return const RoleSelectScreen();
        if (role != _lastRole) {
          _lastRole = role;
          _tab = 0;
        }
        final remitente = role == AppRole.remitente;
        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: [
              remitente ? const EnviosTab(key: ValueKey('envios')) : const ViajarTab(key: ValueKey('viajar')),
              ChatsTab(role: role, onIrAInicio: () => _goTo(0)),
              const PerfilTab(),
            ],
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: _matches,
            builder: (context, _) {
              final unread = _matches.noLeidos(uid);
              final solicitudes = _matches.pendientesComoRemitente(uid);
              return DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Color(0x140B1D39), blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: _goTo,
                  destinations: [
                    if (remitente)
                      NavigationDestination(
                        icon: Badge(isLabelVisible: solicitudes > 0, label: Text('$solicitudes'), child: const Icon(Icons.inventory_2_outlined)),
                        selectedIcon: Badge(isLabelVisible: solicitudes > 0, label: Text('$solicitudes'), child: const Icon(Icons.inventory_2)),
                        label: 'Envíos',
                      )
                    else
                      const NavigationDestination(icon: Icon(Icons.flight_takeoff_outlined), selectedIcon: Icon(Icons.flight_takeoff), label: 'Viajar'),
                    NavigationDestination(
                      icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_outline_rounded)),
                      selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_rounded)),
                      label: 'Chats',
                    ),
                    const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Se muestra si hay sesión pero aún no se eligió rol en este teléfono.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  AppRole _sel = AppRole.remitente;

  @override
  Widget build(BuildContext context) {
    final nombre = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SkyBackdrop(
          seed: 7,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LapticonLogo(light: true),
                          const Spacer(),
                          Text(
                            nombre == null || nombre.isEmpty ? '¿Cómo quieres\nusar Lapticon?' : 'Hola $nombre,\n¿cómo quieres entrar?',
                            style: const TextStyle(color: Colors.white, fontSize: 30, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Puedes cambiar de rol cuando quieras desde tu perfil.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 15),
                          ),
                          const SizedBox(height: 26),
                          RoleSelector(value: _sel, dark: true, onChanged: (r) => setState(() => _sel = r)),
                          const SizedBox(height: 14),
                          Text(_sel.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), height: 1.4)),
                          const Spacer(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.navy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: () => RoleController.instance.set(_sel),
                              child: Text('Entrar como ${_sel.label.toLowerCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
