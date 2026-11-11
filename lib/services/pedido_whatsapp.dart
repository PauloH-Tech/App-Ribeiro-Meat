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
  static String montarMensagem({
    required ConfiguracaoLoja loja,
    required List<ItemCarrinho> itens,
    required DadosCliente cliente,
  }) {
    const linha = '------------------------------';
    final b = StringBuffer()
      ..writeln('*NOVO PEDIDO - ${loja.nomeLoja}*')
      ..writeln()
      ..writeln('*Cliente:* ${cliente.nome.trim()}')
      ..writeln()
      ..writeln('*ITENS (${itens.length})*')
      ..writeln(linha);

    for (var i = 0; i < itens.length; i++) {
      final item = itens[i];
      final qtd = Formatador.quantidade(
        item.quantidade,
        item.produto.unitMeasurement,
      );
      b.writeln('${i + 1}. *${item.produto.name}* - $qtd');
      if (item.preparo != null) {
        b.writeln('   Preparo: ${item.preparo!.name}');
      }
      if (item.observacao.trim().isNotEmpty) {
        b.writeln('   Obs: _${item.observacao.trim()}_');
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

  // encodeComponent usa %20 para espaços (o "+" do queryParameters nem
  // sempre é interpretado como espaço pelo WhatsApp).
  static Uri montarLink(String numero, String mensagem) => Uri.parse(
    'https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}',
  );

  static Future<bool> enviar(String numero, String mensagem) =>
      launchUrl(montarLink(numero, mensagem), mode: LaunchMode.externalApplication);
}
