enum UnitMeasurement {
  kg('kg', 'kg', 'Por quilo'),
  unidade('unidade', 'unidades', 'Por unidade'),
  pacote('pacote', 'pacotes', 'Por pacote'),
  peca('peça', 'peças', 'Por peça');

  final String singular;
  final String plural;
  final String rotulo;

  const UnitMeasurement(this.singular, this.plural, this.rotulo);

  static UnitMeasurement parse(String? valor) {
    final v = (valor ?? '').toLowerCase();
    return UnitMeasurement.values.firstWhere(
      (u) => u.name == v,
      orElse: () => UnitMeasurement.unidade,
    );
  }
}
