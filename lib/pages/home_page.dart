import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/components/barra_carrinho.dart';
import 'package:ribeiro_meat/components/estado_mensagem.dart';
import 'package:ribeiro_meat/components/produto_card.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/categoria.dart';
import 'package:ribeiro_meat/pages/carrinho_page.dart';
import 'package:ribeiro_meat/state/carrinho.dart';
import 'package:ribeiro_meat/state/catalogo_controller.dart';
import 'package:ribeiro_meat/utils/texto.dart';

const double larguraMaxima = 1120;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _busca = TextEditingController();
  int? _categoriaSelecionada; // null = todas

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoController>();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: catalogo.status == StatusCatalogo.pronto
          ? const BarraCarrinho()
          : null,
      body: switch (catalogo.status) {
        StatusCatalogo.carregando => const _Carregando(),
        StatusCatalogo.erro => EstadoMensagem(
          icone: Icons.wifi_off_rounded,
          titulo: 'Ops! Algo deu errado',
          mensagem: catalogo.erro,
          textoAcao: 'Tentar novamente',
          onAcao: catalogo.carregar,
        ),
        StatusCatalogo.pronto => _conteudo(catalogo),
      },
    );
  }

  List<Categoria> _filtrar(List<Categoria> categorias) {
    final termo = normalizar(_busca.text.trim());
    return [
      for (final c in categorias)
        if (_categoriaSelecionada == null || _categoriaSelecionada == c.id)
          Categoria(
            id: c.id,
            name: c.name,
            products: termo.isEmpty
                ? c.products
                : c.products
                      .where(
                        (p) =>
                            normalizar(p.name).contains(termo) ||
                            normalizar(p.description ?? '').contains(termo),
                      )
                      .toList(),
          ),
    ].where((c) => c.products.isNotEmpty).toList();
  }

  Widget _conteudo(CatalogoController catalogo) {
    final largura = MediaQuery.sizeOf(context).width;
    final lateral = ((largura - larguraMaxima) / 2).clamp(16.0, double.infinity);
    final visiveis = _filtrar(catalogo.categorias);

    return RefreshIndicator(
      onRefresh: catalogo.carregar,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: lateral),
            sliver: SliverToBoxAdapter(
              child: _Cabecalho(nomeLoja: catalogo.configuracao?.nomeLoja ?? ''),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FiltrosDelegate(
              lateral: lateral,
              busca: _busca,
              categorias: catalogo.categorias,
              selecionada: _categoriaSelecionada,
              onBusca: () => setState(() {}),
              onCategoria: (id) => setState(() => _categoriaSelecionada = id),
            ),
          ),
          if (visiveis.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EstadoMensagem(
                icone: Icons.search_off_rounded,
                titulo: 'Nenhum produto encontrado',
                mensagem: 'Tente buscar por outro nome ou categoria.',
                textoAcao: 'Limpar filtros',
                onAcao: () => setState(() {
                  _busca.clear();
                  _categoriaSelecionada = null;
                }),
              ),
            ),
          for (final categoria in visiveis) ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(lateral, 20, lateral, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      categoria.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${categoria.products.length}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Cores.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: lateral),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 290,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: categoria.products.length,
                itemBuilder: (_, i) =>
                    ProdutoCard(produto: categoria.products[i]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final String nomeLoja;
  const _Cabecalho({required this.nomeLoja});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final itens = context.select<Carrinho, int>((c) => c.totalItens);

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Cores.vinho, Cores.vinhoEscuro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.kebab_dining_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeLoja,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Catálogo de produtos',
                      style: tema.bodySmall?.copyWith(color: Cores.textoSuave),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Meu pedido',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CarrinhoPage()),
                ),
                icon: Badge(
                  isLabelVisible: itens > 0,
                  label: Text('$itens'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Cores.vinho, Cores.vinhoEscuro],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monte seu pedido e envie\npelo WhatsApp',
                  style: tema.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Passo(numero: 1, texto: 'Escolha os cortes'),
                    _Passo(numero: 2, texto: 'Revise o pedido'),
                    _Passo(numero: 3, texto: 'Envie no WhatsApp'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  final int numero;
  final String texto;
  const _Passo({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Cores.dourado,
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Cores.texto,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosDelegate extends SliverPersistentHeaderDelegate {
  final double lateral;
  final TextEditingController busca;
  final List<Categoria> categorias;
  final int? selecionada;
  final VoidCallback onBusca;
  final ValueChanged<int?> onCategoria;

  _FiltrosDelegate({
    required this.lateral,
    required this.busca,
    required this.categorias,
    required this.selecionada,
    required this.onBusca,
    required this.onCategoria,
  });

  static const double _altura = 128;

  @override
  double get minExtent => _altura;
  @override
  double get maxExtent => _altura;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      decoration: BoxDecoration(
        color: Cores.fundo,
        border: overlaps
            ? const Border(bottom: BorderSide(color: Cores.borda))
            : null,
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: lateral),
            child: SizedBox(
              height: 50,
              child: ValueListenableBuilder(
                valueListenable: busca,
                builder: (context, valor, _) => TextField(
                  controller: busca,
                  onChanged: (_) => onBusca(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar produto...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: valor.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              busca.clear();
                              onBusca();
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: lateral),
              children: [
                _chip('Todos', null),
                for (final c in categorias) _chip(c.name, c.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String rotulo, int? id) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(rotulo),
      selected: selecionada == id,
      onSelected: (_) => onCategoria(id),
    ),
  );

  @override
  bool shouldRebuild(covariant _FiltrosDelegate old) =>
      old.selecionada != selecionada ||
      old.categorias != categorias ||
      old.lateral != lateral;
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kebab_dining_rounded, size: 48, color: Cores.vinho),
          SizedBox(height: 20),
          SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          SizedBox(height: 14),
          Text('Carregando catálogo...'),
        ],
      ),
    );
  }
}
