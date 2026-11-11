import 'package:ribeiro_meat/models/produto.dart';

class Categoria {
  final int id;
  final String name;
  final List<Produto> products;

  const Categoria({
    required this.id,
    required this.name,
    required this.products,
  });

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
    id: j['id'],
    name: j['name'],
    products: ((j['products'] as List?) ?? [])
        .map((item) => Produto.fromJson(item))
        .toList(),
  );
}
