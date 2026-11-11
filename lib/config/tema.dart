import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta baseada na logo Ribeiro Tuiuti (carvão + dourado),
/// com fundo claro e quente para o site não ficar escuro.
class Cores {
  // Dourado da logo
  static const dourado = Color(0xFFE3A82B); // dourado principal
  static const douradoClaro = Color(0xFFF6CD5E); // brilho do degradê
  static const douradoEscuro = Color(
    0xFF9A6B0E,
  ); // textos/ícones dourados sobre fundo claro
  static const douradoSuave = Color(0xFFFBF1DC); // fundos de destaque bem leves

  // Carvão do escudo
  static const carvao = Color(0xFF2B2724);
  static const carvaoClaro = Color(0xFF3A3530);

  // Base clara
  static const fundo = Color(0xFFFAF6EF); // creme quente
  static const superficie = Colors.white;
  static const texto = Color(0xFF221E1B);
  static const textoSuave = Color(0xFF7A7068);
  static const borda = Color(0xFFECE3D6);

  static const whatsapp = Color(0xFF1FAF54);

  /// Degradê dourado igual ao da logo (use em títulos, faixas, botões especiais)
  static const degradeDourado = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [douradoClaro, dourado],
  );

  // Aliases para não quebrar o código antigo — troque aos poucos
  @Deprecated('Use Cores.carvao')
  static const vinho = carvao;
  @Deprecated('Use Cores.carvaoClaro')
  static const vinhoEscuro = carvaoClaro;
}

class Tema {
  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: Cores.dourado,
      brightness: Brightness.light,
      primary: Cores.carvao,
      onPrimary: Cores.dourado,
      secondary: Cores.dourado,
      onSecondary: Cores.carvao,
      tertiary: Cores.douradoEscuro,
      surface: Cores.superficie,
      onSurface: Cores.texto,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Cores.fundo,
    );

    final texto = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: Cores.texto, displayColor: Cores.texto);

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
          borderSide: const BorderSide(color: Cores.dourado, width: 1.6),
        ),
        hintStyle: const TextStyle(color: Cores.textoSuave),
      ),
      // Botão principal: carvão com texto dourado (igual ao escudo da logo)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Cores.carvao,
          foregroundColor: Cores.dourado,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      // Botão secundário: dourado com texto carvão
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Cores.dourado,
          foregroundColor: Cores.carvao,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Cores.carvao,
          side: const BorderSide(color: Cores.dourado, width: 1.4),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Cores.douradoEscuro),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: Cores.borda),
        backgroundColor: Cores.superficie,
        selectedColor: Cores.carvao,
        labelStyle: texto.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        secondaryLabelStyle: texto.labelLarge?.copyWith(
          color: Cores.dourado,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(color: Cores.borda, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Cores.dourado,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Cores.carvao,
        contentTextStyle: texto.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: Cores.dourado,
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
