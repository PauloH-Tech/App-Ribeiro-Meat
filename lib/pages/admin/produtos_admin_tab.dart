import 'package:flutter/material.dart';
import 'package:ribeiro_meat/components/estado_mensagem.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/admin.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/pages/admin/admin_utils.dart';
import 'package:ribeiro_meat/pages/admin/produto_form_page.dart';
import 'package:ribeiro_meat/services/admin_service.dart';
import 'package:ribeiro_meat/services/api_service.dart';
import 'package:ribeiro_meat/utils/formatador.dart';
import 'package:ribeiro_meat/utils/texto.dart';

class ProdutosAdminTab extends StatefulWidget {
  const ProdutosAdminTab({super.key});

  @override
  State<ProdutosAdminTab> createState() => _ProdutosAdminTabState();
}

class _ProdutosAdminTabState extends State<ProdutosAdminTab> {
  List<ProdutoAdmin> _produtos = [];
  List<CategoriaAdmin> _categorias = [];
  List<OpcaoPreparo> _preparos = [];
  bool _carregando = true;
  String? _erro;

  final _busca = TextEditingController();
  int? _categoriaFiltro;
  final Set<int> _alterando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _produtos.isEmpty;
      _erro = null;
    });
    try {
      final r = await Future.wait([
        AdminService.listarProdutos(),
        AdminService.listarCategorias(),
        AdminService.listarPreparos(),
      ]);
      if (!mounted) return;
      setState(() {
        _produtos = r[0] as List<ProdutoAdmin>;
        _categorias = r[1] as List<CategoriaAdmin>;
        _preparos = r[2] as List<OpcaoPreparo>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<ProdutoAdmin> get _filtrados {
    final termo = normalizar(_busca.text.trim());
    return _produtos.where((p) {
      if (_categoriaFiltro != null && p.categoryId != _categoriaFiltro) {
        return false;
      }
      return termo.isEmpty || normalizar(p.name).contains(termo);
    }).toList();
  }

  Future<void> _abrirForm([ProdutoAdmin? produto]) async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProdutoFormPage(
          produto: produto,
          categorias: _categorias,
          preparos: _preparos,
        ),
      ),
    );
    if (alterou == true) _carregar();
  }

  Future<void> _alternarDisponivel(ProdutoAdmin p, bool valor) async {
    setState(() => _alterando.add(p.id));
    final ok = await executarAcao(
      context,
      () => AdminService.alterarDisponibilidade(p.id, valor),
      sucesso: valor
          ? '${p.name} disponível no catálogo'
          : '${p.name} oculto do catálogo',
    );
    if (ok) await _carregar();
    if (mounted) setState(() => _alterando.remove(p.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return EstadoMensagem(
        icone: Icons.cloud_off_rounded,
        titulo: 'Não foi possível carregar',
        mensagem: _erro,
        textoAcao: 'Tentar novamente',
        onAcao: _carregar,
      );
    }

    final lista = _filtrados;
    final padding = paddingResponsivo(context);
    final ocultos = _produtos.where((p) => !p.available).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _categorias.isEmpty ? null : () => _abrirForm(),
        backgroundColor: _categorias.isEmpty ? Cores.borda : Cores.vinho,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo produto'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: padding,
          children: [
            Text(
              '${_produtos.length} produtos'
              '${ocultos > 0 ? ' · $ocultos ocultos do catálogo' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Cores.textoSuave),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _busca,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _busca.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_busca.clear),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Todas', null),
                  for (final c in _categorias) _chip(c.name, c.id),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_categorias.isEmpty)
              const _Aviso(
                'Cadastre uma categoria na aba "Categorias" antes de criar '
                'produtos.',
              )
            else if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EstadoMensagem(
                  icone: Icons.inventory_2_outlined,
                  titulo: 'Nenhum produto encontrado',
                ),
              ),
            for (final p in lista) ...[
              _ProdutoTile(
                produto: p,
                alterando: _alterando.contains(p.id),
                onTap: () => _abrirForm(p),
                onDisponivel: (v) => _alternarDisponivel(p, v),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String rotulo, int? id) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(rotulo),
      selected: _categoriaFiltro == id,
      onSelected: (_) => setState(() => _categoriaFiltro = id),
    ),
  );
}

class _ProdutoTile extends StatelessWidget {
  final ProdutoAdmin produto;
  final bool alterando;
  final VoidCallback onTap;
  final ValueChanged<bool> onDisponivel;

  const _ProdutoTile({
    required this.produto,
    required this.alterando,
    required this.onTap,
    required this.onDisponivel,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final p = produto;
    final min = Formatador.quantidade(p.minQuantity, p.unitMeasurement);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: p.available ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: (p.imageUrl ?? '').isEmpty
                        ? _semFoto()
                        : Image.network(
                            p.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _semFoto(),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.categoryName} · ${p.unitMeasurement.rotulo} · mín. $min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.bodySmall?.copyWith(
                          color: Cores.textoSuave,
                        ),
                      ),
                      if (p.preparationOptions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.preparationOptions.map((o) => o.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.bodySmall?.copyWith(color: Cores.vinho),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    alterando
                        ? const SizedBox(
                            width: 52,
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : Switch(
                            value: p.available,
                            onChanged: onDisponivel,
                          ),
                    Text(
                      p.available ? 'Visível' : 'Oculto',
                      style: tema.labelSmall?.copyWith(
                        color: Cores.textoSuave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _semFoto() => Container(
    color: const Color(0xFFF6E3D8),
    child: Icon(
      Icons.image_outlined,
      color: Cores.vinho.withValues(alpha: 0.4),
    ),
  );
}

class _Aviso extends StatelessWidget {
  final String texto;
  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.dourado.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Cores.texto),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
