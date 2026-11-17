import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/admin.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/unidade_medida.dart';
import 'package:ribeiro_meat/pages/admin/admin_utils.dart';
import 'package:ribeiro_meat/services/admin_service.dart';
import 'package:ribeiro_meat/utils/arquivo_imagem.dart';
import 'package:ribeiro_meat/utils/formatador.dart';

/// Cadastro/edição de produto. Retorna true (via pop) se algo foi salvo.
class ProdutoFormPage extends StatefulWidget {
  final ProdutoAdmin? produto;
  final List<CategoriaAdmin> categorias;
  final List<OpcaoPreparo> preparos;

  const ProdutoFormPage({
    super.key,
    this.produto,
    required this.categorias,
    required this.preparos,
  });

  @override
  State<ProdutoFormPage> createState() => _ProdutoFormPageState();
}

class _ProdutoFormPageState extends State<ProdutoFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _minimo;
  late final TextEditingController _incremento;
  late final TextEditingController _pesoAproximado;
  late final TextEditingController _preco;

  late int? _categoriaId;
  late UnitMeasurement _unidade;
  late bool _disponivel;
  late bool _precoPorKg;
  late Set<int> _preparosSelecionados;
  late List<OpcaoPreparo> _preparos;
  bool _salvando = false;

  /// URL da foto salva no produto (null = sem foto).
  String? _fotoAtual;

  /// Foto escolhida que ainda não foi enviada (vai para o S3 ao salvar).
  Uint8List? _novaFoto;
  String? _tipoNovaFoto;

  bool get _temFoto => _novaFoto != null || _fotoAtual != null;

  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    _nome = TextEditingController(text: p?.name ?? '');
    _descricao = TextEditingController(text: p?.description ?? '');
    final url = p?.imageUrl?.trim() ?? '';
    _fotoAtual = url.isEmpty ? null : url;
    _unidade = p?.unitMeasurement ?? UnitMeasurement.kg;
    _minimo = TextEditingController(
      text: Formatador.numero(p?.minQuantity ?? _padrao(_unidade).$1),
    );
    _incremento = TextEditingController(
      text: Formatador.numero(p?.increment ?? _padrao(_unidade).$2),
    );
    _pesoAproximado = TextEditingController(
      text: p?.approxWeight == null ? '' : Formatador.numero(p!.approxWeight!),
    );
    _preco = TextEditingController(
      text: p?.price == null
          ? ''
          : p!.price!.toStringAsFixed(2).replaceAll('.', ','),
    );
    _categoriaId =
        p?.categoryId ??
        (widget.categorias.length == 1 ? widget.categorias.first.id : null);
    _disponivel = p?.available ?? true;
    _precoPorKg = p?.pricePerKg ?? false;
    _preparosSelecionados = {...?p?.preparationOptions.map((o) => o.id)};
    _preparos = [...widget.preparos];
    for (final c in [_minimo, _incremento]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _descricao,
      _minimo,
      _incremento,
      _pesoAproximado,
      _preco,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// (mínimo, incremento) sugeridos por unidade.
  static (double, double) _padrao(UnitMeasurement u) =>
      u == UnitMeasurement.kg ? (0.5, 0.25) : (1, 1);

  static double? _lerNumero(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  void _mudarUnidade(UnitMeasurement u) {
    final (min, inc) = _padrao(u);
    setState(() {
      _unidade = u;
      _minimo.text = Formatador.numero(min);
      _incremento.text = Formatador.numero(inc);
    });
  }

  String? _validarNumero(String? v) {
    final n = _lerNumero(v ?? '');
    if (n == null) return 'Número inválido';
    if (n <= 0) return 'Deve ser maior que zero';
    if (n > 9999) return 'Valor muito alto';
    return null;
  }

  /// Opcional: vazio = sem preço ("sob consulta" para o cliente).
  String? _validarPreco(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = _lerNumero(v!);
    if (n == null) return 'Número inválido';
    if (n <= 0) return 'Deve ser maior que zero';
    if (n >= 100000000) return 'Valor muito alto';
    if ((n * 100 - (n * 100).round()).abs() > 0.0001) {
      return 'Use no máximo 2 casas decimais';
    }
    return null;
  }

  /// Exemplo das quantidades que o cliente poderá escolher.
  String? get _exemploQuantidades {
    final min = _lerNumero(_minimo.text);
    final inc = _lerNumero(_incremento.text);
    if (min == null || inc == null || min <= 0 || inc <= 0) return null;
    final valores = [
      for (var i = 0; i < 4; i++)
        Formatador.quantidade(min + inc * i, _unidade),
    ];
    return 'O cliente poderá escolher: ${valores.join(', ')}...';
  }

  Future<void> _novoPreparo() async {
    final nome = await pedirTexto(
      context,
      titulo: 'Nova opção de preparo',
      rotulo: 'Nome (ex.: Moída, Bife, Cubos)',
    );
    if (nome == null || !mounted) return;
    final ok = await executarAcao(
      context,
      () => AdminService.salvarPreparo(nome: nome),
    );
    if (!ok || !mounted) return;
    final lista = await AdminService.listarPreparos();
    final criado = lista.where(
      (o) => o.name.toLowerCase() == nome.toLowerCase(),
    );
    setState(() {
      _preparos = lista;
      if (criado.isNotEmpty) _preparosSelecionados.add(criado.first.id);
    });
  }

  Future<void> _escolherFoto() async {
    final XFile? arquivo;
    try {
      // Reduz no próprio aparelho: foto de celular fica leve e abaixo de 5 MB.
      arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível abrir a foto', erro: true);
      }
      return;
    }
    if (arquivo == null) return; // cancelou
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    final tipo = ArquivoImagem.tipo(bytes);
    if (tipo == null) {
      mostrarMensagem(
        context,
        'Formato não suportado. Use JPG, PNG ou WEBP.',
        erro: true,
      );
      return;
    }
    if (bytes.length > ArquivoImagem.tamanhoMaximo) {
      mostrarMensagem(context, 'A foto deve ter no máximo 5 MB.', erro: true);
      return;
    }
    setState(() {
      _novaFoto = bytes;
      _tipoNovaFoto = tipo;
    });
  }

  Widget _previaFoto() {
    if (_novaFoto != null) {
      return Image.memory(_novaFoto!, fit: BoxFit.cover);
    }
    if (_fotoAtual != null) {
      return Image.network(
        _fotoAtual!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _semFoto('Não foi possível carregar a foto'),
      );
    }
    return _semFoto('Sem foto');
  }

  Widget _semFoto(String texto) => Container(
    color: Cores.fundo,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.image_outlined, size: 40, color: Cores.textoSuave),
        const SizedBox(height: 6),
        Text(texto, style: const TextStyle(color: Cores.textoSuave)),
      ],
    ),
  );

  void _removerFoto() => setState(() {
    _novaFoto = null;
    _tipoNovaFoto = null;
    _fotoAtual = null;
  });

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);

    // 1) Envia a foto nova (se houver) e usa a URL devolvida pela API.
    if (_novaFoto != null) {
      String? url;
      final enviou = await executarAcao(context, () async {
        url = await AdminService.enviarImagem(_novaFoto!, _tipoNovaFoto!);
      });
      if (!mounted) return;
      if (!enviou) {
        setState(() => _salvando = false);
        return;
      }
      // Se o passo 2 falhar, um novo "Salvar" não reenvia a mesma foto.
      setState(() {
        _fotoAtual = url;
        _novaFoto = null;
        _tipoNovaFoto = null;
      });
    }

    // 2) Salva o produto. A API apaga do S3 a foto antiga, se ela mudou.
    final form = ProdutoForm(
      categoryId: _categoriaId!,
      name: _nome.text,
      description: _descricao.text,
      imageUrl: _fotoAtual ?? '',
      unitMeasurement: _unidade,
      minQuantity: _lerNumero(_minimo.text)!,
      increment: _lerNumero(_incremento.text)!,
      available: _disponivel,
      preparationOptionIds: _preparosSelecionados,
      approxWeight: _unidade == UnitMeasurement.peca
          ? _lerNumero(_pesoAproximado.text)
          : null,
      price: _lerNumero(_preco.text),
      pricePerKg: _unidade == UnitMeasurement.peca && _precoPorKg,
    );
    final ok = await executarAcao(
      context,
      () => AdminService.salvarProduto(id: widget.produto?.id, form: form),
      sucesso: _editando ? 'Produto atualizado' : 'Produto cadastrado',
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _excluir() async {
    final p = widget.produto!;
    final sim = await confirmar(
      context,
      titulo: 'Excluir produto?',
      mensagem:
          '"${p.name}" será removido do catálogo e do painel. '
          'Se quiser apenas escondê-lo por um tempo, desmarque "Visível no catálogo".',
    );
    if (!sim || !mounted) return;
    final ok = await executarAcao(
      context,
      () => AdminService.excluirProduto(p.id),
      sucesso: 'Produto excluído',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final sufixo = _unidade == UnitMeasurement.kg ? 'kg' : _unidade.plural;
    final exemplo = _exemploQuantidades;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar produto' : 'Novo produto'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              onPressed: _salvando ? null : _excluir,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Cores.vinho,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: paddingResponsivo(context, max: 720),
          children: [
            _Secao(
              titulo: 'Informações',
              children: [
                TextFormField(
                  controller: _nome,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome do produto *',
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descricao,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: carne macia, ideal para bifes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _categoriaId,
                  decoration: const InputDecoration(labelText: 'Categoria *'),
                  items: [
                    for (final c in widget.categorias)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoriaId = v),
                  validator: (v) => v == null ? 'Escolha a categoria' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visível no catálogo'),
                  subtitle: const Text(
                    'Desmarque quando o produto estiver em falta',
                  ),
                  value: _disponivel,
                  onChanged: (v) => setState(() => _disponivel = v),
                ),
              ],
            ),
            _Secao(
              titulo: 'Venda',
              children: [
                Text(
                  'Unidade de venda',
                  style: tema.labelLarge?.copyWith(color: Cores.textoSuave),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final u in UnitMeasurement.values)
                      ChoiceChip(
                        label: Text(u.rotulo),
                        selected: _unidade == u,
                        onSelected: (_) => _mudarUnidade(u),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _preco,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Preço',
                    prefixText: 'R\$ ',
                    suffixText: _unidade == UnitMeasurement.peca && _precoPorKg
                        ? 'por kg'
                        : 'por ${_unidade.singular}',
                    helperText: 'Deixe vazio para mostrar "sob consulta"',
                  ),
                  validator: _validarPreco,
                ),
                if (_unidade == UnitMeasurement.peca)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Preço por kg'),
                    subtitle: const Text(
                      'A peça é pesada na hora da venda e cobrada pelo kg',
                    ),
                    value: _precoPorKg,
                    onChanged: (v) => setState(() => _precoPorKg = v),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minimo,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Quantidade mínima',
                          suffixText: sufixo,
                        ),
                        validator: _validarNumero,
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _incremento,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Aumenta de',
                          suffixText: sufixo,
                        ),
                        validator: _validarNumero,
                      ),
                    ),
                  ],
                ),
                if (exemplo != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    exemplo,
                    style: tema.bodySmall?.copyWith(color: Cores.textoSuave),
                  ),
                ],
                if (_unidade == UnitMeasurement.peca) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pesoAproximado,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Peso aproximado da peça',
                      suffixText: 'Kg',
                    ),

                    validator: _validarNumero,
                  ),
                ],
              ],
            ),
            _Secao(
              titulo: 'Opções de preparo',
              subtitulo: 'O cliente escolhe uma delas (opcional)',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in _preparos)
                      FilterChip(
                        label: Text(o.name),
                        selected: _preparosSelecionados.contains(o.id),
                        selectedColor: Cores.vinho,
                        checkmarkColor: Colors.white,
                        showCheckmark: true,
                        labelStyle: TextStyle(
                          color: _preparosSelecionados.contains(o.id)
                              ? Colors.white
                              : Cores.texto,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (sel) => setState(() {
                          sel
                              ? _preparosSelecionados.add(o.id)
                              : _preparosSelecionados.remove(o.id);
                        }),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nova opção'),
                      onPressed: _novoPreparo,
                    ),
                  ],
                ),
              ],
            ),
            _Secao(
              titulo: 'Foto',
              subtitulo: 'Aparece no catálogo · JPG, PNG ou WEBP, até 5 MB',
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _previaFoto(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _salvando ? null : _escolherFoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_temFoto ? 'Trocar foto' : 'Escolher foto'),
                    ),
                    if (_temFoto)
                      TextButton.icon(
                        onPressed: _salvando ? null : _removerFoto,
                        style: TextButton.styleFrom(
                          foregroundColor: Cores.vinho,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remover foto'),
                      ),
                  ],
                ),
                if (_novaFoto != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Nova foto escolhida. Ela será enviada ao salvar.',
                    style: tema.bodySmall?.copyWith(color: Cores.textoSuave),
                  ),
                ] else if (!_temFoto && widget.produto?.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'A foto será removida ao salvar.',
                    style: tema.bodySmall?.copyWith(color: Cores.textoSuave),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Cores.superficie,
            border: Border(top: BorderSide(color: Cores.borda)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 688),
              child: FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _editando ? 'Salvar alterações' : 'Cadastrar produto',
                ),
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
  final String? subtitulo;
  final List<Widget> children;

  const _Secao({required this.titulo, this.subtitulo, required this.children});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titulo,
                style: tema.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitulo != null)
                Text(
                  subtitulo!,
                  style: tema.bodySmall?.copyWith(color: Cores.textoSuave),
                ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
