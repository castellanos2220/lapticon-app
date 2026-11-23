import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Identidad visual de Lapticon: azul noche profundo, celeste eléctrico y un
/// tono kraft (cartón de encomienda) para los detalles del paquete.
class AppColors {
  static const ink = Color(0xFF060E1F);
  static const navy = Color(0xFF0B1D39);
  static const navyLight = Color(0xFF1B3A66);
  static const royal = Color(0xFF2F6BFF);
  static const sky = Color(0xFF5FB3FF);
  static const skySoft = Color(0xFFE8F3FF);
  static const mist = Color(0xFFF3F5FA);
  static const line = Color(0xFFE3E8F0);
  static const kraft = Color(0xFFD9A86C);
  static const kraftDeep = Color(0xFF8A5A2B);
  static const kraftSoft = Color(0xFFF7EBDD);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
}

/// Degradado de las cabeceras inmersivas y barras superiores.
/// Tipografía incluida en la app (assets/fonts, licencia OFL).
const appFont = 'PlusJakartaSans';

const heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.ink, AppColors.navy, Color(0xFF173663)],
  stops: [0, 0.55, 1],
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.navy).copyWith(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.sky,
    onSecondary: AppColors.navy,
    surface: Colors.white,
    error: AppColors.danger,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: appFont);
  final text = base.textTheme.apply(fontFamily: appFont, bodyColor: AppColors.navy, displayColor: AppColors.navy);
  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: AppColors.mist,
    visualDensity: VisualDensity.standard,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: TextStyle(fontFamily: appFont, color: Colors.white, fontWeight: FontWeight.w600),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.skySoft,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(fontFamily: appFont, 
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? AppColors.navy : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.navy : AppColors.muted),
      ),
    ),
  );
}

/// Barra superior oscura con degradado, coherente con las cabeceras inmersivas.
PreferredSizeWidget lapAppBar(String title, {List<Widget>? actions, PreferredSizeWidget? bottom, Widget? titleWidget}) {
  return AppBar(
    title: titleWidget ?? Text(title, style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, color: Colors.white, fontSize: 19)),
    backgroundColor: AppColors.navy,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: heroGradient)),
    actions: actions,
    bottom: bottom,
  );
}

/// Decoración estándar de campos de formulario.
InputDecoration fieldDeco(String label, {IconData? icon, String? hint, String? helper, Widget? suffix}) {
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.navyLight),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.royal, 2),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 2),
  );
}
