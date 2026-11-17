import 'package:ribeiro_meat/models/produto.dart';

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

  /// Ex.: 1234.5 -> "R$ 1.234,50".
  static String moeda(double v) {
    final centavos = (v * 100).round();
    final abs = centavos.abs();
    final reais = (abs ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final cents = (abs % 100).toString().padLeft(2, '0');
    return '${centavos < 0 ? '-' : ''}R\$ $reais,$cents';
  }

  /// Preço informativo. Ex.: "R$ 45,00/kg", "R$ 30,00/peça", ou "/kg" para
  /// peça cobrada por kg. null quando o produto não tem preço.
  static String? preco(Produto p) => p.price == null
      ? null
      : '${moeda(p.price!)}/${p.pricePerKg ? 'kg' : p.unitMeasurement.singular}';

  static String? pesoAproximado(Produto p) =>
      p.unitMeasurement == UnitMeasurement.peca && p.approxWeight != null
      ? 'Aprox. ${numero(p.approxWeight!)} kg'
      : null;
}
