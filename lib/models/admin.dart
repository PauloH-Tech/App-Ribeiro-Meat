import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/unidade_medida.dart';

/// Categoria como retornada por /v1/admin/categorias.
class CategoriaAdmin {
  final int id;
  final String name;
  final int displayOrder;

  const CategoriaAdmin({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  factory CategoriaAdmin.fromJson(Map<String, dynamic> j) => CategoriaAdmin(
    id: j['id'],
    name: j['name'],
    displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
  );
}

/// Produto como retornado por /v1/admin/produtos.
class ProdutoAdmin {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final UnitMeasurement unitMeasurement;
  final double minQuantity;
  final double increment;
  final bool available;
  final int categoryId;
  final String categoryName;
  final List<OpcaoPreparo> preparationOptions;

  const ProdutoAdmin({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.unitMeasurement,
    required this.minQuantity,
    required this.increment,
    required this.available,
    required this.categoryId,
    required this.categoryName,
    required this.preparationOptions,
  });

  factory ProdutoAdmin.fromJson(Map<String, dynamic> j) => ProdutoAdmin(
    id: j['id'],
    name: j['name'],
    description: j['description'],
    imageUrl: j['imageUrl'],
    unitMeasurement: UnitMeasurement.parse(j['unitMeasurement']),
    minQuantity: (j['minQuantity'] as num).toDouble(),
    increment: (j['increment'] as num).toDouble(),
    available: j['available'] == true,
    categoryId: j['categoryId'],
    categoryName: j['categoryName'] ?? '',
    preparationOptions: ((j['preparationOptions'] as List?) ?? [])
        .map((o) => OpcaoPreparo.fromJson(o))
        .toList(),
  );
}

/// Corpo enviado em POST/PUT de produto.
class ProdutoForm {
  final int categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final UnitMeasurement unitMeasurement;
  final double minQuantity;
  final double increment;
  final bool available;
  final Set<int> preparationOptionIds;

  const ProdutoForm({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.unitMeasurement,
    required this.minQuantity,
    required this.increment,
    required this.available,
    required this.preparationOptionIds,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'name': name.trim(),
    'description': description.trim().isEmpty ? null : description.trim(),
    'imageUrl': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
    'unitMeasurement': unitMeasurement.name.toUpperCase(),
    'minQuantity': minQuantity,
    'increment': increment,
    'available': available,
    'preparationOptionIds': preparationOptionIds.toList(),
  };
}
