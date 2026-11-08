import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/unidade_medida.dart';

export 'package:ribeiro_meat/models/unidade_medida.dart';

class Produto {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final UnitMeasurement unitMeasurement;
  final double minQuantity;
  final double increment;
  final List<OpcaoPreparo> preparationOptions;

  const Produto({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.unitMeasurement,
    required this.minQuantity,
    required this.increment,
    required this.preparationOptions,
  });

  bool get temImagem => imageUrl != null && imageUrl!.trim().isNotEmpty;

  factory Produto.fromJson(Map<String, dynamic> j) {
    final unidade = UnitMeasurement.parse(j['unitMeasurement'] as String?);
    final min = (j['minQuantity'] as num?)?.toDouble() ?? 0;
    final inc = (j['increment'] as num?)?.toDouble() ?? 0;
    final padrao = unidade == UnitMeasurement.kg ? 0.5 : 1.0;
    return Produto(
      id: j['id'],
      name: j['name'],
      description: j['description'],
      imageUrl: j['imageUrl'],
      unitMeasurement: unidade,
      minQuantity: min > 0 ? min : padrao,
      increment: inc > 0 ? inc : padrao,
      preparationOptions: ((j['preparationOptions'] as List?) ?? [])
          .map((item) => OpcaoPreparo.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'unitMeasurement': unitMeasurement.name.toUpperCase(),
    'minQuantity': minQuantity,
    'increment': increment,
    'preparationOptions': preparationOptions.map((o) => o.toJson()).toList(),
  };
}
