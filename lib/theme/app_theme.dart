import 'package:flutter/material.dart';

/// Tema único de la app: colores, tipografía y espaciado se definen aquí.
class AppTheme {
  AppTheme._();

  static const double espacio = 16;
  static const Color semilla = Color(0xFF5D4037); // marrón cuero de libro

  static ThemeData claro() => _tema(Brightness.light);
  static ThemeData oscuro() => _tema(Brightness.dark);

  static ThemeData _tema(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(seedColor: semilla, brightness: brillo);
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      appBarTheme: AppBarTheme(centerTitle: false, backgroundColor: esquema.surface, scrolledUnderElevation: 1),
      cardTheme: CardThemeData(elevation: 0, color: esquema.surfaceContainerHighest.withValues(alpha: 0.5), margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))),
    );
  }
}
