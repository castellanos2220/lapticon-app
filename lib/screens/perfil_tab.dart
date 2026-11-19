import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  late Future<Map<String, dynamic>?> _perfil = LapticonApi.instance.miPerfil();

  void _recargar() => setState(() => _perfil = LapticonApi.instance.miPerfil());

  Future<void> _salir() async {
    final ok = await confirmar(context, titulo: 'Cerrar sesión', mensaje: '¿Seguro que quieres salir de Lapticon?', ok: 'Cerrar sesión');
    if (ok) await FirebaseAuth.instance.signOut();
  }

  Future<void> _editar(Map<String, dynamic>? actual) async {
    final guardado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PerfilFormScreen(actual: actual)));
    if (guardado == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: lapAppBar('Perfil'),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _perfil,
        builder: (context, snap) {
          final p = snap.data;
          final nombre = p == null
              ? (user?.displayName ?? 'Tu perfil')
              : '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim();
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SurfaceCard(
                  child: Row(
                    children: [
                      Avatar(nombre.isEmpty ? (user?.email ?? '?') : nombre, size: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre.isEmpty ? 'Sin nombre' : nombre, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.navy)),
                            const SizedBox(height: 2),
                            Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator(color: AppColors.sky))
                else if (snap.hasError)
                  InfoBanner(icon: Icons.cloud_off_rounded, color: AppColors.warning, text: errorText(snap.error!), action: TextButton(onPressed: _recargar, child: const Text('Reintentar')))
                else if (p == null)
                  InfoBanner(
                    icon: Icons.person_add_alt_1_rounded,
                    color: AppColors.warning,
                    text: 'Completa tu perfil en el servidor para poder publicar envíos y vuelos.',
                    action: TextButton(onPressed: () => _editar(null), child: const Text('Completar')),
                  )
                else
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _Fila(Icons.phone_outlined, 'Teléfono', '${p['telefono'] ?? '—'}'),
                        const Divider(height: 1, indent: 56),
                        _Fila(Icons.flag_outlined, 'Nacionalidad', '${p['nacionalidad'] ?? '—'}'),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.edit_outlined, color: AppColors.navyLight),
                          title: const Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.w700)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _editar(p),
                        ),
                      ],
                    ),
                  ),
                const SectionTitle('Cómo funciona'),
                const SurfaceCard(
                  child: Column(
                    children: [
                      _Paso(n: 1, titulo: 'Publica tu envío', texto: 'Qué es, tamaño, ciudad de origen y destino, fecha límite y cuánto pagas.'),
                      _Paso(n: 2, titulo: 'Solo lo ven viajeros compatibles', texto: 'Personas con vuelo en tu misma ruta que llegan antes de tu fecha límite.'),
                      _Paso(n: 3, titulo: 'Match', texto: 'Un viajero se interesa y tú lo aceptas. Desde ese momento pueden chatear.'),
                      _Paso(n: 4, titulo: 'Entrega', texto: 'Acuerden por chat la entrega y marca el envío como entregado.', ultimo: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _salir,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Servidor: ${Uri.parse(AppConfig.apiBaseUrl).host}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;
  const _Fila(this.icon, this.titulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navyLight),
      title: Text(titulo, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      subtitle: Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }
}

class _Paso extends StatelessWidget {
  final int n;
  final String titulo;
  final String texto;
  final bool ultimo;
  const _Paso({required this.n, required this.titulo, required this.texto, this.ultimo = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(texto, style: const TextStyle(color: AppColors.muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Crear o editar el perfil en el backend (POST /api/users/register o PUT /api/users/:uid).
class PerfilFormScreen extends StatefulWidget {
  final Map<String, dynamic>? actual;
  const PerfilFormScreen({super.key, this.actual});

  @override
  State<PerfilFormScreen> createState() => _PerfilFormScreenState();
}

class _PerfilFormScreenState extends State<PerfilFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: '${widget.actual?['nombre'] ?? ''}');
  late final _apellido = TextEditingController(text: '${widget.actual?['apellido'] ?? ''}');
  late final _telefono = TextEditingController(text: '${widget.actual?['telefono'] ?? ''}');
  late final _nacionalidad = TextEditingController(text: '${widget.actual?['nacionalidad'] ?? 'Colombia'}');
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _telefono, _nacionalidad]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final datos = {
      'nombre': _nombre.text.trim(),
      'apellido': _apellido.text.trim(),
      'telefono': _telefono.text.trim(),
      'nacionalidad': _nacionalidad.text.trim(),
    };
    try {
      if (widget.actual == null) {
        await LapticonApi.instance.registrarPerfil(
          nombre: datos['nombre']!,
          apellido: datos['apellido']!,
          telefono: datos['telefono']!,
          nacionalidad: datos['nacionalidad']!,
        );
      } else {
        await LapticonApi.instance.actualizarPerfil(datos);
      }
      await FirebaseAuth.instance.currentUser?.updateDisplayName('${datos['nombre']} ${datos['apellido']}');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) => (v ?? '').trim().length >= 2 ? null : 'Campo obligatorio';
    return Scaffold(
      appBar: lapAppBar(widget.actual == null ? 'Completar perfil' : 'Editar perfil'),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(controller: _nombre, textCapitalization: TextCapitalization.words, decoration: fieldDeco('Nombre'), validator: req),
              const SizedBox(height: 14),
              TextFormField(controller: _apellido, textCapitalization: TextCapitalization.words, decoration: fieldDeco('Apellido'), validator: req),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: fieldDeco('Teléfono', icon: Icons.phone_outlined),
                validator: (v) => RegExp(r'^\+?[0-9 ]{7,15}$').hasMatch((v ?? '').trim()) ? null : 'Teléfono no válido',
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _nacionalidad, textCapitalization: TextCapitalization.words, decoration: fieldDeco('Nacionalidad', icon: Icons.flag_outlined), validator: req),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Guardar', icon: Icons.check_rounded, busy: _busy, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
