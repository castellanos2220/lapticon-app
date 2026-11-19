import 'package:flutter/material.dart';

/// Identidad visual de Lapticon: azul noche, celeste, blanco y un tono kraft
/// (cartón de encomienda) para los detalles del paquete.
class AppColors {
  static const navy = Color(0xFF0B1D39);
  static const navyLight = Color(0xFF1B3A66);
  static const sky = Color(0xFF5FB3FF);
  static const skySoft = Color(0xFFE8F3FF);
  static const mist = Color(0xFFF4F6FA);
  static const line = Color(0xFFE3E8F0);
  static const kraft = Color(0xFFD4A373);
  static const kraftSoft = Color(0xFFF7EBDD);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.navy).copyWith(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.sky,
    onSecondary: AppColors.navy,
    surface: Colors.white,
    error: AppColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.mist,
    visualDensity: VisualDensity.standard,
  );
}

/// AppBar plana y coherente en todas las pantallas.
PreferredSizeWidget lapAppBar(String title, {List<Widget>? actions, PreferredSizeWidget? bottom, Widget? titleWidget}) {
  return AppBar(
    title: titleWidget ?? Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
    backgroundColor: AppColors.mist,
    foregroundColor: AppColors.navy,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    actions: actions,
    bottom: bottom,
  );
}

/// Decoración estándar de campos de formulario.
InputDecoration fieldDeco(String label, {IconData? icon, String? hint, String? helper, Widget? suffix}) {
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.sky, 2),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 2),
  );
}
