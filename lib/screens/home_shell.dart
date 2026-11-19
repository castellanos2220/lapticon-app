import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/matches_controller.dart';
import '../theme.dart';
import 'chats_tab.dart';
import 'envios_tab.dart';
import 'perfil_tab.dart';
import 'viajar_tab.dart';

/// Navegación principal: Envíos (remitente) · Viajar (viajero) · Chats · Perfil.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _matches = MatchesController.instance;

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
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const EnviosTab(),
          const ViajarTab(),
          ChatsTab(onIrAEnvios: () => _goTo(0), onIrAViajar: () => _goTo(1)),
          const PerfilTab(),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _matches,
        builder: (context, _) {
          final unread = _matches.noLeidos(uid);
          final solicitudes = _matches.pendientesComoRemitente(uid);
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _goTo,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.skySoft,
            destinations: [
              NavigationDestination(
                icon: Badge(isLabelVisible: solicitudes > 0, label: Text('$solicitudes'), child: const Icon(Icons.inventory_2_outlined)),
                selectedIcon: Badge(isLabelVisible: solicitudes > 0, label: Text('$solicitudes'), child: const Icon(Icons.inventory_2)),
                label: 'Envíos',
              ),
              const NavigationDestination(icon: Icon(Icons.flight_takeoff_outlined), selectedIcon: Icon(Icons.flight_takeoff), label: 'Viajar'),
              NavigationDestination(
                icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_outline_rounded)),
                selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_rounded)),
                label: 'Chats',
              ),
              const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
            ],
          );
        },
      ),
    );
  }
}
