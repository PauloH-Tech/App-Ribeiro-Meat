import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/components/adicionar_produto_sheet.dart';
import 'package:ribeiro_meat/components/estado_mensagem.dart';
import 'package:ribeiro_meat/components/imagem_produto.dart';
import 'package:ribeiro_meat/components/seletor_quantidade.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/item_carrinho.dart';
import 'package:ribeiro_meat/services/pedido_whatsapp.dart';
import 'package:ribeiro_meat/state/carrinho.dart';
import 'package:ribeiro_meat/state/catalogo_controller.dart';
import 'package:ribeiro_meat/utils/formatador.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarrinhoPage extends StatefulWidget {
  const CarrinhoPage({super.key});

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  static const _kNome = 'cliente_nome';

  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _obs = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosCliente();
    // Atualiza a prévia da mensagem conforme o cliente digita.
    for (final c in [_nome, _obs]) {
      c.addListener(_atualizar);
    }
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nome.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosCliente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _nome.text = prefs.getString(_kNome) ?? '');
    } catch (_) {}
  }

  Future<void> _salvarDadosCliente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNome, _nome.text.trim());
    } catch (_) {}
  }

  DadosCliente get _cliente =>
      DadosCliente(nome: _nome.text, observacao: _obs.text);

  void _remover(ItemCarrinho item) {
    final carrinho = context.read<Carrinho>();
    final posicao = carrinho.itens.indexOf(item);
    carrinho.remover(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.produto.name} removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            textColor: Cores.dourado,
            onPressed: () => carrinho.inserir(posicao, item),
          ),
        ),
      );
  }

  Future<void> _limpar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar pedido?'),
        content: const Text('Todos os itens serão removidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.read<Carrinho>().limpar();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha seus dados para enviar.')),
      );
      return;
    }
    final loja = context.read<CatalogoController>().configuracao;
    final carrinho = context.read<Carrinho>();
    if (loja == null || loja.numeroWhatsapp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp da loja não configurado.')),
      );
      return;
    }

    final mensagem = PedidoWhatsapp.montarMensagem(
      loja: loja,
      itens: carrinho.itens,
      cliente: _cliente,
    );

    // Abre o WhatsApp imediatamente (sem await antes) para que o navegador
    // não bloqueie a nova aba como pop-up.
    final abriu = await PedidoWhatsapp.enviar(loja.numeroWhatsapp, mensagem);
    _salvarDadosCliente();
    if (!mounted) return;

    if (!abriu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
      return;
    }
    _confirmarEnvio(carrinho);
  }

  Future<void> _confirmarEnvio(Carrinho carrinho) async {
    final novo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Cores.whatsapp, size: 48),
        title: const Text('Pedido pronto!'),
        content: const Text(
          'Abrimos o WhatsApp com seu pedido. Confira a mensagem e toque em '
          'enviar na conversa. O vendedor vai confirmar com você.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter itens'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Novo pedido'),
          ),
        ],
      ),
    );
    if (novo == true && mounted) {
      carrinho.limpar();
      _obs.clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<Carrinho>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu pedido'),
        actions: [
          if (!carrinho.vazio)
            TextButton.icon(
              onPressed: _limpar,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Limpar'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: carrinho.vazio
          ? EstadoMensagem(
              icone: Icons.shopping_bag_outlined,
              titulo: 'Seu pedido está vazio',
              mensagem: 'Adicione produtos do catálogo para montar seu pedido.',
              textoAcao: 'Ver catálogo',
              onAcao: () => Navigator.of(context).pop(),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      ((MediaQuery.sizeOf(context).width - 680) / 2).clamp(
                        16.0,
                        double.infinity,
                      ),
                  vertical: 8,
                ),
                children: [
                  _Secao(
                    titulo: 'Itens',
                    detalhe: '${carrinho.totalItens}',
                    child: Column(
                      children: [
                        for (var i = 0; i < carrinho.itens.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Cores.borda),
                          _LinhaItem(
                            item: carrinho.itens[i],
                            onRemover: () => _remover(carrinho.itens[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adicionar mais produtos'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Secao(
                    titulo: 'Seus dados',
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nome,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Seu nome',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => (v ?? '').trim().length < 2
                                ? 'Informe seu nome'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _obs,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              labelText: 'Observações (opcional)',
                              hintText: 'Ex.: preciso para sábado de manhã',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PreviaMensagem(montar: () {
                    final loja = context.read<CatalogoController>().configuracao;
                    if (loja == null) return '';
                    return PedidoWhatsapp.montarMensagem(
                      loja: loja,
                      itens: carrinho.itens,
                      cliente: _cliente,
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: carrinho.vazio
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Cores.superficie,
                  border: Border(top: BorderSide(color: Cores.borda)),
                ),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 648),
                    child: FilledButton.icon(
                      onPressed: _enviar,
                      style: FilledButton.styleFrom(
                        backgroundColor: Cores.whatsapp,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Enviar pedido pelo WhatsApp'),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final String? detalhe;
  final Widget child;
  const _Secao({required this.titulo, this.detalhe, required this.child});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
          child: Row(
            children: [
              Text(
                titulo,
                style: tema.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (detalhe != null) ...[
                const SizedBox(width: 8),
                Text(detalhe!, style: tema.titleSmall?.copyWith(color: Cores.textoSuave)),
              ],
            ],
          ),
        ),
        Card(clipBehavior: Clip.antiAlias, child: child),
      ],
    );
  }
}

class _LinhaItem extends StatelessWidget {
  final ItemCarrinho item;
  final VoidCallback onRemover;
  const _LinhaItem({required this.item, required this.onRemover});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final carrinho = context.read<Carrinho>();
    final p = item.produto;
    final detalhes = [
      if (item.preparo != null) item.preparo!.name,
      if (item.observacao.isNotEmpty) '"${item.observacao}"',
    ];

    return InkWell(
      onTap: () => AdicionarProdutoSheet.abrir(context, p, editando: item),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 60,
                height: 60,
                child: ImagemProduto(produto: p, tamanhoIcone: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (detalhes.isNotEmpty)
                    Text(
                      detalhes.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.bodySmall?.copyWith(color: Cores.textoSuave),
                    ),
                  const SizedBox(height: 8),
                  SeletorQuantidade(
                    compacto: true,
                    valor: Formatador.quantidade(
                      item.quantidade,
                      p.unitMeasurement,
                    ),
                    onMenos: item.quantidade - p.increment >= p.minQuantity - 0.0001
                        ? () => carrinho.decrementar(item)
                        : null,
                    onMais: () => carrinho.incrementar(item),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () =>
                      AdicionarProdutoSheet.abrir(context, p, editando: item),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: onRemover,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Cores.vinho,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviaMensagem extends StatelessWidget {
  final String Function() montar;
  const _PreviaMensagem({required this.montar});

  /// Renderiza *negrito* e _itálico_ como o WhatsApp faz.
  static TextSpan _formatarWhatsapp(String texto) {
    final regex = RegExp(r'\*([^*\n]+)\*|_([^_\n]+)_');
    final spans = <TextSpan>[];
    var inicio = 0;
    for (final m in regex.allMatches(texto)) {
      if (m.start > inicio) {
        spans.add(TextSpan(text: texto.substring(inicio, m.start)));
      }
      spans.add(
        m.group(1) != null
            ? TextSpan(
                text: m.group(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            : TextSpan(
                text: m.group(2),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
      );
      inicio = m.end;
    }
    spans.add(TextSpan(text: texto.substring(inicio)));
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.chat_outlined, color: Cores.whatsapp),
        title: const Text(
          'Prévia da mensagem',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCF8C6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText.rich(
              _formatarWhatsapp(montar()),
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
