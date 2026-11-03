import 'package:flutter/material.dart';

/// Tipografía y tema base. El color de cada pantalla lo decide su [Scene]
/// (ver `core/widgets/sentence.dart`), no el tema.
abstract final class AppTheme {
  static const displayFamily = 'Bricolage';
  static const bodyFamily = 'Atkinson';

  static const utezGreen = Color(0xFF009475);

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  /// Bricolage es variable: el peso se fija con el eje `wght` y el tamaño
  /// óptico con `opsz`.
  static TextStyle display(
    double size, {
    double weight = 600,
    double height = 1.08,
    Color? color,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    height: height,
    color: color,
    letterSpacing: -0.025 * size,
    fontVariations: [
      FontVariation.weight(weight),
      FontVariation('opsz', size.clamp(12, 96)),
    ],
  );

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: utezGreen,
      brightness: brightness,
    );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: bodyFamily,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
