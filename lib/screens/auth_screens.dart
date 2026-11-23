import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../services/api.dart';
import '../services/role.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/immersive.dart';
import '../widgets/role_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  AppRole _role = RoleController.instance.value ?? AppRole.remitente;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await RoleController.instance.set(_role);
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showError(context, ApiException('Escribe tu correo arriba y vuelve a tocar "¿Olvidaste tu contraseña?".'));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) showOk(context, 'Si existe una cuenta con $email, te enviamos un enlace para restablecerla.');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Hola de nuevo',
      subtitle: 'Elige cómo entras hoy e inicia sesión.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthLabel('Entrar como'),
            RoleSelector(value: _role, onChanged: (r) => setState(() => _role = r)),
            const SizedBox(height: 22),
            const AuthLabel('Tu cuenta'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: fieldDeco('Correo electrónico', icon: Icons.alternate_email),
              validator: (v) => (v ?? '').contains('@') ? null : 'Escribe un correo válido',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: _hide,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: fieldDeco(
                'Contraseña',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _hide ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: (v) => (v ?? '').length >= 6 ? null : 'Mínimo 6 caracteres',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _reset, child: const Text('¿Olvidaste tu contraseña?')),
            ),
            const SizedBox(height: 6),
            PrimaryButton(label: 'Entrar como ${_role.label.toLowerCase()}', icon: _role.icon, busy: _busy, onPressed: _login),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('¿No tienes cuenta? Crea una'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _nacionalidad = TextEditingController(text: 'Colombia');
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  AppRole _role = RoleController.instance.value ?? AppRole.remitente;

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _telefono, _nacionalidad, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await RoleController.instance.set(_role);
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text);
      final nombreCompleto = '${_nombre.text.trim()} ${_apellido.text.trim()}';
      await cred.user?.updateDisplayName(nombreCompleto);
      await cred.user?.reload();
      String? avisoPerfil;
      try {
        await LapticonApi.instance.registrarPerfil(
          nombre: _nombre.text.trim(),
          apellido: _apellido.text.trim(),
          telefono: _telefono.text.trim(),
          nacionalidad: _nacionalidad.text.trim(),
        );
      } catch (e) {
        avisoPerfil = errorText(e);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      if (avisoPerfil != null) {
        messenger.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 8),
          content: Text('Tu cuenta se creó, pero el perfil no se guardó en el servidor: $avisoPerfil. Complétalo en la pestaña Perfil.'),
        ));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) => (v ?? '').trim().length >= 2 ? null : 'Campo obligatorio';
    return AuthScaffold(
      title: 'Crea tu cuenta',
      subtitle: 'Una sola cuenta para enviar y para viajar. Elige con cuál empiezas.',
      child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthLabel('Quiero empezar como'),
              RoleSelector(value: _role, onChanged: (r) => setState(() => _role = r)),
              const SizedBox(height: 10),
              Text(_role.description, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35)),
              const SizedBox(height: 22),
              const AuthLabel('Tus datos'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: fieldDeco('Nombre'),
                      validator: req,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellido,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: fieldDeco('Apellido'),
                      validator: req,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: fieldDeco('Teléfono', icon: Icons.phone_outlined, hint: '3001234567'),
                validator: (v) => RegExp(r'^\+?[0-9 ]{7,15}$').hasMatch((v ?? '').trim()) ? null : 'Teléfono no válido',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nacionalidad,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: fieldDeco('Nacionalidad', icon: Icons.flag_outlined),
                validator: req,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: fieldDeco('Correo electrónico', icon: Icons.alternate_email),
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Correo no válido',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: fieldDeco(
                  'Contraseña',
                  icon: Icons.lock_outline,
                  helper: 'Mínimo 6 caracteres',
                  suffix: IconButton(
                    tooltip: _hide ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: (v) => (v ?? '').length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Crear cuenta de ${_role.label.toLowerCase()}', icon: Icons.person_add_alt_1_rounded, busy: _busy, onPressed: _register),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Ya tengo cuenta'),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

/// Cabecera inmersiva + hoja clara con el formulario.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.mist,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            SkyBackdrop(
              seed: 6,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, pad.top + 4, 24, 58),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Volver',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                          const SizedBox(height: 8),
                          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 15, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0, -28, 0),
              decoration: const BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(20, 26, 20, 24 + pad.bottom),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthLabel extends StatelessWidget {
  final String text;
  const AuthLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: AppColors.muted)),
    );
  }
}
