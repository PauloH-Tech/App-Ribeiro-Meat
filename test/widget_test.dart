import 'package:flutter_test/flutter_test.dart';
import 'package:ribeiro_meat/models/configuracao_loja.dart';
import 'package:ribeiro_meat/models/item_carrinho.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/produto.dart';
import 'package:ribeiro_meat/services/pedido_whatsapp.dart';
import 'package:ribeiro_meat/utils/formatador.dart';

void main() {
  const patinho = Produto(
    id: 1,
    name: 'Patinho',
    unitMeasurement: UnitMeasurement.kg,
    minQuantity: 0.5,
    increment: 0.25,
    preparationOptions: [OpcaoPreparo(id: 3, name: 'Bife')],
  );

  test('formata quantidades', () {
    expect(Formatador.quantidade(0.5, UnitMeasurement.kg), '500 g');
    expect(Formatador.quantidade(1.25, UnitMeasurement.kg), '1,25 kg');
    expect(Formatador.quantidade(2, UnitMeasurement.kg), '2 kg');
    expect(Formatador.quantidade(1, UnitMeasurement.peca), '1 peça');
    expect(Formatador.quantidade(3, UnitMeasurement.unidade), '3 unidades');
  });

  test('monta mensagem e link do WhatsApp', () {
    const loja = ConfiguracaoLoja(
      nomeLoja: 'Casa de Carnes',
      nomeWhatsapp: 'Vendedor',
      numeroWhatsapp: '5544999999999',
    );
    final msg = PedidoWhatsapp.montarMensagem(
      loja: loja,
      itens: [
        ItemCarrinho(
          produto: patinho,
          quantidade: 1.5,
          preparo: patinho.preparationOptions.first,
          observacao: 'sem gordura',
        ),
      ],
      cliente: const DadosCliente(nome: 'Maria', observacao: 'Para sábado'),
    );
    expect(msg, contains('*Patinho* - 1,5 kg'));
    expect(msg, contains('Preparo: Bife'));
    expect(msg, contains('Para sábado'));
    // Sem emojis/símbolos fora do Latin-1 (viram "?" em alguns WhatsApp).
    expect(msg.runes.every((r) => r <= 0xFF), isTrue);

    final link = PedidoWhatsapp.montarLink(loja.numeroWhatsapp, msg).toString();
    expect(link, startsWith('https://wa.me/5544999999999?text='));
    expect(link, isNot(contains('+')));
  });
}
