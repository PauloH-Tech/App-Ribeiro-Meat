class ConfiguracaoLoja {
  final String nomeLoja;
  final String nomeWhatsapp;
  final String numeroWhatsapp;
  final String instagram;
  final String numeroFixo;
  final String numero;
  final String endereco;

  const ConfiguracaoLoja({
    required this.nomeLoja,
    required this.nomeWhatsapp,
    required this.numeroWhatsapp,
    required this.instagram,
    required this.numeroFixo,
    required this.endereco,
    required this.numero
  });

  factory ConfiguracaoLoja.fromJson(Map<String, dynamic> j) => ConfiguracaoLoja(
    nomeLoja: (j['nomeLoja'] as String?) ?? 'Casa de Carnes Ribeiro',
    nomeWhatsapp: (j['nomeWhatsapp'] as String?) ?? '',
    // Mantém apenas os dígitos (formato exigido pelo wa.me)
    numeroWhatsapp: ((j['numeroWhatsapp'] as String?) ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    ),
    numeroFixo: ((j['numeroFixo'] as String?) ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    ),
    instagram: (j['instagram'] as String?) ?? '',
    endereco: (j['endereco'] as String?) ?? '',
    numero: (j['numero'] as String?) ?? '',
  );
}
