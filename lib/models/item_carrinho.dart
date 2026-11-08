import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/produto.dart';

class ItemCarrinho {
  final Produto produto;
  final double quantidade;
  final OpcaoPreparo? preparo;
  final String observacao;

  const ItemCarrinho({
    required this.produto,
    required this.quantidade,
    this.preparo,
    this.observacao = '',
  });

  /// Itens com mesmo produto, preparo e observação são agrupados.
  String get chave =>
      '${produto.id}|${preparo?.id ?? 0}|${observacao.trim().toLowerCase()}';

  ItemCarrinho copyWith({double? quantidade}) => ItemCarrinho(
    produto: produto,
    quantidade: quantidade ?? this.quantidade,
    preparo: preparo,
    observacao: observacao,
  );

  factory ItemCarrinho.fromJson(Map<String, dynamic> j) => ItemCarrinho(
    produto: Produto.fromJson(j['produto']),
    quantidade: (j['quantidade'] as num).toDouble(),
    preparo: j['preparo'] == null ? null : OpcaoPreparo.fromJson(j['preparo']),
    observacao: (j['observacao'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'produto': produto.toJson(),
    'quantidade': quantidade,
    'preparo': preparo?.toJson(),
    'observacao': observacao,
  };
}
