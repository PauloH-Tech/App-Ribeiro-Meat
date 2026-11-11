class ConfiguracaoLoja {
  final String nomeLoja;
  final String nomeWhatsapp;
  final String numeroWhatsapp;

  const ConfiguracaoLoja({
    required this.nomeLoja,
    required this.nomeWhatsapp,
    required this.numeroWhatsapp,
  });

  factory ConfiguracaoLoja.fromJson(Map<String, dynamic> j) => ConfiguracaoLoja(
    nomeLoja: (j['nomeLoja'] as String?) ?? 'Casa de Carnes Ribeiro',
    nomeWhatsapp: (j['nomeWhatsapp'] as String?) ?? '',
    // Mantém apenas os dígitos (formato exigido pelo wa.me)
    numeroWhatsapp: ((j['numeroWhatsapp'] as String?) ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    ),
  );
}
