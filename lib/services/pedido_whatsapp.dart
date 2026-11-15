import 'package:ribeiro_meat/models/categoria.dart';
import 'package:ribeiro_meat/models/configuracao_loja.dart';
import 'package:ribeiro_meat/models/item_carrinho.dart';
import 'package:ribeiro_meat/utils/formatador.dart';
import 'package:url_launcher/url_launcher.dart';

class DadosCliente {
  final String nome;
  final String observacao;

  const DadosCliente({required this.nome, this.observacao = ''});
}

class PedidoWhatsapp {
  /// Monta o texto do pedido usando a formatação do WhatsApp
  /// (*negrito*, _itálico_).
  ///
  /// Usa apenas texto simples (sem emojis nem símbolos especiais): alguns
  /// aparelhos/versões do WhatsApp exibem emojis vindos do link wa.me como
  /// "?" ou "�".
  ///
  /// Os itens saem agrupados por categoria (na ordem do [categorias]) e, dentro
  /// de cada uma, em ordem alfabética de produto e preparo — assim o mesmo
  /// produto com preparos diferentes fica junto. Itens cujo produto não está
  /// no catálogo vão para "Outros", no fim.
  static String montarMensagem({
    required ConfiguracaoLoja loja,
    required List<ItemCarrinho> itens,
    required DadosCliente cliente,
    List<Categoria> categorias = const [],
  }) {
    const linha = '------------------------------';
    final b = StringBuffer()
      ..writeln('*NOVO PEDIDO - ${loja.nomeLoja}*')
      ..writeln()
      ..writeln('*Cliente:* ${cliente.nome.trim()}')
      ..writeln()
      ..writeln('*ITENS (${itens.length})*')
      ..writeln(linha);

    var numero = 1;
    final grupos = _agrupar(itens, categorias);
    for (var g = 0; g < grupos.length; g++) {
      final (nomeCategoria, itensGrupo) = grupos[g];
      if (g > 0) b.writeln();
      b.writeln('*${nomeCategoria.toUpperCase()}*');
      for (final item in itensGrupo) {
        final qtd = Formatador.quantidade(
          item.quantidade,
          item.produto.unitMeasurement,
        );
        final preparo = item.preparo == null ? '' : ' - ${item.preparo!.name}';
        b.writeln('${numero++}. *${item.produto.name}* - $qtd$preparo');
        if (item.observacao.trim().isNotEmpty) {
          b.writeln('   Obs: _${item.observacao.trim()}_');
        }
      }
    }

    b.writeln(linha);

    if (cliente.observacao.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('*Observações:* ${cliente.observacao.trim()}');
    }

    b
      ..writeln()
      ..write('_Pedido enviado pelo catálogo online._');

    return b.toString();
  }

  /// Agrupa os itens por categoria e ordena cada grupo por produto e preparo.
  static List<(String, List<ItemCarrinho>)> _agrupar(
    List<ItemCarrinho> itens,
    List<Categoria> categorias,
  ) {
    // produto.id -> posição da categoria no catálogo
    final indiceDoProduto = <int, int>{
      for (var c = 0; c < categorias.length; c++)
        for (final p in categorias[c].products) p.id: c,
    };
    final semCategoria = categorias.length;

    final porCategoria = <int, List<(int, ItemCarrinho)>>{};
    for (var i = 0; i < itens.length; i++) {
      final c = indiceDoProduto[itens[i].produto.id] ?? semCategoria;
      porCategoria.putIfAbsent(c, () => []).add((i, itens[i]));
    }

    final ordemCategorias = porCategoria.keys.toList()..sort();
    return [
      for (final c in ordemCategorias)
        (
          c == semCategoria ? 'Outros' : categorias[c].name,
          (porCategoria[c]!..sort(_compararItens)).map((e) => e.$2).toList(),
        ),
    ];
  }

  /// Produto, depois preparo (sem preparo primeiro); empate mantém a ordem
  /// em que foram adicionados ao carrinho.
  static int _compararItens((int, ItemCarrinho) a, (int, ItemCarrinho) b) {
    var r = _chave(a.$2.produto.name).compareTo(_chave(b.$2.produto.name));
    if (r != 0) return r;
    r = _chave(a.$2.preparo?.name ?? '').compareTo(
      _chave(b.$2.preparo?.name ?? ''),
    );
    if (r != 0) return r;
    return a.$1.compareTo(b.$1);
  }

  /// Minúsculas e sem acento, para "Acém" ficar antes de "Bisteca".
  static String _chave(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final buf = StringBuffer();
    for (final ch in s.trim().toLowerCase().split('')) {
      final i = de.indexOf(ch);
      buf.write(i >= 0 ? para[i] : ch);
    }
    return buf.toString();
  }

  // encodeComponent usa %20 para espaços (o "+" do queryParameters nem
  // sempre é interpretado como espaço pelo WhatsApp).
  static Uri montarLink(String numero, String mensagem) => Uri.parse(
    'https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}',
  );

  static Future<bool> enviar(String numero, String mensagem) =>
      launchUrl(montarLink(numero, mensagem), mode: LaunchMode.externalApplication);
}
