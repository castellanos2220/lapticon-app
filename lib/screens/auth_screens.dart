import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'welcome_screen.dart';

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
    return Scaffold(
      appBar: lapAppBar(''),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const LapticonLogo(),
              const SizedBox(height: 28),
              const Text('Hola de nuevo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.navy)),
              const SizedBox(height: 6),
              const Text('Inicia sesión para ver tus envíos y chats.', style: TextStyle(color: AppColors.muted, fontSize: 15)),
              const SizedBox(height: 28),
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
              const SizedBox(height: 8),
              PrimaryButton(label: 'Entrar', icon: Icons.login_rounded, busy: _busy, onPressed: _login),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('¿No tienes cuenta? Crea una'),
                ),
              ),
            ],
          ),
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
    return Scaffold(
      appBar: lapAppBar('Crear cuenta'),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const Text(
                'Con una sola cuenta puedes enviar encargos y también llevarlos en tus vuelos.',
                style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 22),
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
              PrimaryButton(label: 'Crear cuenta', icon: Icons.person_add_alt_1_rounded, busy: _busy, onPressed: _register),
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
      ),
    );
  }
}
