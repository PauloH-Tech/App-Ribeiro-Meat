import 'package:ribeiro_meat/models/unidade_medida.dart';

class Formatador {
  /// Arredonda para evitar erros de ponto flutuante (0.1 + 0.2...).
  static double arredondar(double v) => (v * 1000).round() / 1000;

  static String numero(double v) {
    final r = arredondar(v);
    if (r == r.roundToDouble()) return r.toInt().toString();
    final s = r.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
    return s.replaceAll('.', ',');
  }

  /// Ex.: 0.5 kg -> "500 g", 1.25 kg -> "1,25 kg", 2 peça -> "2 peças".
  static String quantidade(double v, UnitMeasurement unidade) {
    final q = arredondar(v);
    if (unidade == UnitMeasurement.kg) {
      if (q < 1) return '${(q * 1000).round()} g';
      return '${numero(q)} kg';
    }
    return '${numero(q)} ${q == 1 ? unidade.singular : unidade.plural}';
  }
}
