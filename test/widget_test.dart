import 'package:flutter_test/flutter_test.dart';
import 'package:ribeiro_meat/models/categoria.dart';
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
    expect(msg, contains('*Patinho* - 1,5 kg - Bife'));
    expect(msg, contains('Para sábado'));
    // Sem emojis/símbolos fora do Latin-1 (viram "?" em alguns WhatsApp).
    expect(msg.runes.every((r) => r <= 0xFF), isTrue);

    final link = PedidoWhatsapp.montarLink(loja.numeroWhatsapp, msg).toString();
    expect(link, startsWith('https://wa.me/5544999999999?text='));
    expect(link, isNot(contains('+')));
  });

  test('formata preços (por unidade e por kg)', () {
    expect(Formatador.moeda(0), 'R\$ 0,00');
    expect(Formatador.moeda(45), 'R\$ 45,00');
    expect(Formatador.moeda(1234.5), 'R\$ 1.234,50');
    expect(Formatador.moeda(1234567.891), 'R\$ 1.234.567,89');

    const alcatra = Produto(
      id: 5,
      name: 'Alcatra',
      unitMeasurement: UnitMeasurement.kg,
      minQuantity: 0.5,
      increment: 0.25,
      preparationOptions: [],
      price: 49.9,
    );
    const costela = Produto(
      id: 6,
      name: 'Costela',
      unitMeasurement: UnitMeasurement.peca,
      minQuantity: 1,
      increment: 1,
      preparationOptions: [],
      price: 30,
    );
    const picanha = Produto(
      id: 7,
      name: 'Picanha',
      unitMeasurement: UnitMeasurement.peca,
      minQuantity: 1,
      increment: 1,
      preparationOptions: [],
      approxWeight: 1,
      price: 79.9,
      pricePerKg: true,
    );
    expect(Formatador.preco(alcatra), 'R\$ 49,90/kg');
    expect(Formatador.preco(costela), 'R\$ 30,00/peça');
    expect(Formatador.preco(picanha), 'R\$ 79,90/kg');
    expect(Formatador.preco(patinho), isNull);

    // Preço é só informativo: não entra na mensagem do pedido.
    const loja = ConfiguracaoLoja(
      nomeLoja: 'Casa de Carnes',
      nomeWhatsapp: 'Vendedor',
      numeroWhatsapp: '5544999999999',
    );
    final msg = PedidoWhatsapp.montarMensagem(
      loja: loja,
      itens: const [ItemCarrinho(produto: picanha, quantidade: 2)],
      cliente: const DadosCliente(nome: 'Maria'),
    );
    expect(msg, contains('*Picanha* - 2 peças'));
    expect(msg, isNot(contains('R\$')));
  });

  test('pricePerKg vem do JSON e é falso por padrão', () {
    final base = {
      'id': 1,
      'name': 'Picanha',
      'unitMeasurement': 'PECA',
      'minQuantity': 1,
      'increment': 1,
      'price': 79.9,
    };
    expect(Produto.fromJson(base).pricePerKg, isFalse);
    expect(Produto.fromJson({...base, 'pricePerKg': true}).pricePerKg, isTrue);
  });

  test('agrupa itens por categoria e ordena por produto e preparo', () {
    const loja = ConfiguracaoLoja(
      nomeLoja: 'Casa de Carnes',
      nomeWhatsapp: 'Vendedor',
      numeroWhatsapp: '5544999999999',
    );
    Produto prod(int id, String nome) => Produto(
      id: id,
      name: nome,
      unitMeasurement: UnitMeasurement.kg,
      minQuantity: 0.5,
      increment: 0.25,
      preparationOptions: const [],
    );
    final acem = prod(10, 'Acém');
    final bisteca = prod(20, 'Bisteca');
    final linguica = prod(21, 'Linguiça');
    final avulso = prod(99, 'Carvão');
    const moida = OpcaoPreparo(id: 1, name: 'Moída');
    const bife = OpcaoPreparo(id: 2, name: 'Bife');

    final msg = PedidoWhatsapp.montarMensagem(
      loja: loja,
      cliente: const DadosCliente(nome: 'Maria'),
      categorias: [
        Categoria(id: 1, name: 'Bovinos', products: [patinho, acem]),
        Categoria(id: 2, name: 'Suínos', products: [bisteca, linguica]),
      ],
      itens: [
        ItemCarrinho(produto: linguica, quantidade: 1),
        ItemCarrinho(produto: patinho, quantidade: 1, preparo: moida),
        ItemCarrinho(produto: avulso, quantidade: 1),
        ItemCarrinho(produto: acem, quantidade: 1),
        ItemCarrinho(produto: bisteca, quantidade: 1),
        ItemCarrinho(produto: patinho, quantidade: 1, preparo: bife),
      ],
    );

    final ordem = [
      '*BOVINOS*',
      '1. *Acém*',
      '2. *Patinho* - 1 kg - Bife',
      '3. *Patinho* - 1 kg - Moída',
      '*SUÍNOS*',
      '4. *Bisteca*',
      '5. *Linguiça*',
      '*OUTROS*',
      '6. *Carvão*',
    ].map(msg.indexOf).toList();
    expect(ordem.every((i) => i >= 0), isTrue, reason: msg);
    expect(ordem, orderedEquals([...ordem]..sort()), reason: msg);
  });
}
