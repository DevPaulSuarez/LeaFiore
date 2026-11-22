import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const green900 = Color(0xFF1F3326);
  static const green800 = Color(0xFF2F4A36);
  static const green700 = Color(0xFF3F6B48);
  static const green600 = Color(0xFF5A8F5F);
  static const green500 = Color(0xFF74A874);
  static const green300 = Color(0xFFB7D3AD);
  static const green100 = Color(0xFFE6F0DE);
  static const ink = Color(0xFF1D2B21);
  static const muted = Color(0xFF5F7264);
  static const amber = Color(0xFFD89A2B);
  static const red = Color(0xFFC4553F);
  static const bg = Color(0xFFCFDCCB);

  static Color glass([double a = .42]) => Colors.white.withValues(alpha: a);
  static Color glassBorder = Colors.white.withValues(alpha: .7);

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green500, green700],
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.green600, surface: C.bg),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.green900.withValues(alpha: .94),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
    ),
  );
}

TextStyle serif(double size, {Color color = Colors.white, FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.cormorantGaramond(fontSize: size, color: color, fontWeight: weight, letterSpacing: .5);
