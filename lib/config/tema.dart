import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cores {
  static const vinho = Color(0xFF9E1B1F);
  static const vinhoEscuro = Color(0xFF6E0F12);
  static const dourado = Color(0xFFE2A93B);
  static const fundo = Color(0xFFF8F4F0);
  static const superficie = Colors.white;
  static const texto = Color(0xFF231C19);
  static const textoSuave = Color(0xFF7A6E68);
  static const borda = Color(0xFFEAE2DB);
  static const whatsapp = Color(0xFF1FAF54);
}

class Tema {
  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: Cores.vinho,
      primary: Cores.vinho,
      secondary: Cores.dourado,
      surface: Cores.superficie,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Cores.fundo,
    );

    final texto = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: Cores.texto,
      displayColor: Cores.texto,
    );

    final bordaCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Cores.borda),
    );

    return base.copyWith(
      textTheme: texto,
      appBarTheme: AppBarTheme(
        backgroundColor: Cores.fundo,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Cores.texto,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Cores.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Cores.borda),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Cores.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: bordaCampo,
        enabledBorder: bordaCampo,
        focusedBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: Cores.vinho, width: 1.6),
        ),
        hintStyle: const TextStyle(color: Cores.textoSuave),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: Cores.borda),
        backgroundColor: Cores.superficie,
        selectedColor: Cores.vinho,
        labelStyle: texto.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        secondaryLabelStyle: texto.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Cores.texto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Cores.superficie,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
    );
  }
}
