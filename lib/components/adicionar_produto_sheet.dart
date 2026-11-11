import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/components/imagem_produto.dart';
import 'package:ribeiro_meat/components/seletor_quantidade.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/item_carrinho.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/produto.dart';
import 'package:ribeiro_meat/state/carrinho.dart';
import 'package:ribeiro_meat/utils/formatador.dart';

/// Folha inferior para escolher quantidade, preparo e observação.
class AdicionarProdutoSheet extends StatefulWidget {
  final Produto produto;
  final ItemCarrinho? editando;

  const AdicionarProdutoSheet({super.key, required this.produto, this.editando});

  static Future<void> abrir(
    BuildContext context,
    Produto produto, {
    ItemCarrinho? editando,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AdicionarProdutoSheet(produto: produto, editando: editando),
    );
  }

  @override
  State<AdicionarProdutoSheet> createState() => _AdicionarProdutoSheetState();
}

class _AdicionarProdutoSheetState extends State<AdicionarProdutoSheet> {
  late double _quantidade;
  OpcaoPreparo? _preparo;
  late final TextEditingController _obs;

  Produto get p => widget.produto;
  bool get _editando => widget.editando != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editando;
    _quantidade = e?.quantidade ?? p.minQuantity;
    _preparo =
        e?.preparo ??
        (p.preparationOptions.length == 1 ? p.preparationOptions.first : null);
    _obs = TextEditingController(text: e?.observacao ?? '');
  }

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  bool get _podeDiminuir => _quantidade - p.increment >= p.minQuantity - 0.0001;

  void _alterar(double delta) {
    HapticFeedback.selectionClick();
    setState(() => _quantidade = Formatador.arredondar(_quantidade + delta));
  }

  /// Sugestões rápidas de quantidade (somente para produtos por kg).
  List<double> get _sugestoes {
    if (p.unitMeasurement != UnitMeasurement.kg) return [];
    final base = [0.5, 1.0, 1.5, 2.0, 3.0, 5.0];
    return base.where((v) {
      if (v < p.minQuantity - 0.0001) return false;
      final passos = (v - p.minQuantity) / p.increment;
      return (passos - passos.round()).abs() < 0.001;
    }).toList();
  }

  void _confirmar() {
    final carrinho = context.read<Carrinho>();
    final qtdTexto = Formatador.quantidade(_quantidade, p.unitMeasurement);
    if (_editando) {
      carrinho.substituir(
        widget.editando!,
        ItemCarrinho(
          produto: p,
          quantidade: _quantidade,
          preparo: _preparo,
          observacao: _obs.text.trim(),
        ),
      );
    } else {
      carrinho.adicionar(
        p,
        _quantidade,
        preparo: _preparo,
        observacao: _obs.text,
      );
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Cores.dourado),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _editando
                      ? 'Item atualizado'
                      : '$qtdTexto de ${p.name} no pedido',
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    final qtdTexto = Formatador.quantidade(_quantidade, p.unitMeasurement);

    return Padding(
      padding: EdgeInsets.only(bottom: teclado),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: ImagemProduto(produto: p, tamanhoIcone: 64),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    p.name,
                    style: tema.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((p.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.description!,
                      style: tema.bodyMedium?.copyWith(color: Cores.textoSuave),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _Titulo(
                    'Quantidade',
                    detalhe: p.unitMeasurement == UnitMeasurement.kg
                        ? 'Mínimo ${Formatador.quantidade(p.minQuantity, p.unitMeasurement)}'
                        : p.unitMeasurement.rotulo,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SeletorQuantidade(
                      valor: qtdTexto,
                      onMenos: _podeDiminuir
                          ? () => _alterar(-p.increment)
                          : null,
                      onMais: () => _alterar(p.increment),
                    ),
                  ),
                  if (_sugestoes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final s in _sugestoes)
                          ChoiceChip(
                            label: Text(
                              Formatador.quantidade(s, p.unitMeasurement),
                            ),
                            selected:
                                (Formatador.arredondar(s) == _quantidade),
                            onSelected: (_) =>
                                setState(() => _quantidade = s),
                          ),
                      ],
                    ),
                  ],
                  if (p.preparationOptions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _Titulo('Como você prefere?', detalhe: 'Opcional'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in p.preparationOptions)
                          ChoiceChip(
                            label: Text(o.name),
                            selected: _preparo == o,
                            onSelected: (sel) =>
                                setState(() => _preparo = sel ? o : null),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _Titulo('Observação', detalhe: 'Opcional'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _obs,
                    maxLines: 2,
                    minLines: 1,
                    maxLength: 140,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ex.: cortar fino, tirar a gordura...',
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Cores.borda)),
            ),
            child: FilledButton.icon(
              onPressed: _confirmar,
              icon: Icon(
                _editando ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
              ),
              label: Text(
                _editando ? 'Salvar alterações' : 'Adicionar · $qtdTexto',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  final String? detalhe;
  const _Titulo(this.texto, {this.detalhe});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          texto,
          style: tema.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (detalhe != null)
          Text(
            detalhe!,
            style: tema.labelMedium?.copyWith(color: Cores.textoSuave),
          ),
      ],
    );
  }
}
