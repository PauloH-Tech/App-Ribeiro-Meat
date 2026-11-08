import 'package:flutter/material.dart';
import 'package:ribeiro_meat/components/estado_mensagem.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/admin.dart';
import 'package:ribeiro_meat/pages/admin/admin_utils.dart';
import 'package:ribeiro_meat/services/admin_service.dart';
import 'package:ribeiro_meat/services/api_service.dart';

class CategoriasAdminTab extends StatefulWidget {
  const CategoriasAdminTab({super.key});

  @override
  State<CategoriasAdminTab> createState() => _CategoriasAdminTabState();
}

class _CategoriasAdminTabState extends State<CategoriasAdminTab> {
  List<CategoriaAdmin> _categorias = [];
  bool _carregando = true;
  bool _salvandoOrdem = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final lista = await AdminService.listarCategorias();
      if (mounted) setState(() => _categorias = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _nova() async {
    final nome = await pedirTexto(
      context,
      titulo: 'Nova categoria',
      rotulo: 'Nome (ex.: Bovinos, Suínos, Aves)',
      maxLength: 80,
    );
    if (nome == null || !mounted) return;
    final proxima = _categorias.isEmpty
        ? 0
        : _categorias.map((c) => c.displayOrder).reduce((a, b) => a > b ? a : b) + 1;
    final ok = await executarAcao(
      context,
      () => AdminService.salvarCategoria(nome: nome, ordem: proxima),
      sucesso: 'Categoria criada',
    );
    if (ok) _carregar();
  }

  Future<void> _renomear(CategoriaAdmin c) async {
    final nome = await pedirTexto(
      context,
      titulo: 'Renomear categoria',
      rotulo: 'Nome',
      inicial: c.name,
      maxLength: 80,
    );
    if (nome == null || nome == c.name || !mounted) return;
    final ok = await executarAcao(
      context,
      () => AdminService.salvarCategoria(
        id: c.id,
        nome: nome,
        ordem: c.displayOrder,
      ),
      sucesso: 'Categoria atualizada',
    );
    if (ok) _carregar();
  }

  Future<void> _excluir(CategoriaAdmin c) async {
    final sim = await confirmar(
      context,
      titulo: 'Excluir "${c.name}"?',
      mensagem:
          'Só é possível excluir categorias sem produtos. '
          'Mova ou exclua os produtos dela antes.',
    );
    if (!sim || !mounted) return;
    final ok = await executarAcao(
      context,
      () => AdminService.excluirCategoria(c.id),
      sucesso: 'Categoria excluída',
    );
    if (ok) _carregar();
  }

  /// Reordena e grava a nova ordem (só as categorias que mudaram).
  Future<void> _reordenar(int de, int para) async {
    if (de == para) return;
    final nova = [..._categorias];
    nova.insert(para, nova.removeAt(de));
    setState(() {
      _categorias = nova;
      _salvandoOrdem = true;
    });
    await executarAcao(context, () async {
      for (var i = 0; i < nova.length; i++) {
        final c = nova[i];
        if (c.displayOrder != i) {
          await AdminService.salvarCategoria(id: c.id, nome: c.name, ordem: i);
        }
      }
    }, sucesso: 'Ordem atualizada');
    await _carregar();
    if (mounted) setState(() => _salvandoOrdem = false);
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
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nova,
        backgroundColor: Cores.vinho,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova categoria'),
      ),
      body: _categorias.isEmpty
          ? const EstadoMensagem(
              icone: Icons.category_outlined,
              titulo: 'Nenhuma categoria',
              mensagem: 'Crie categorias como Bovinos, Suínos e Aves.',
            )
          : ReorderableListView.builder(
              padding: paddingResponsivo(context, max: 720),
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Arraste para mudar a ordem em que aparecem no catálogo.',
                        style: tema.bodyMedium?.copyWith(
                          color: Cores.textoSuave,
                        ),
                      ),
                    ),
                    if (_salvandoOrdem)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              itemCount: _categorias.length,
              onReorderItem: _salvandoOrdem ? (_, _) {} : _reordenar,
              itemBuilder: (context, i) {
                final c = _categorias[i];
                return Padding(
                  key: ValueKey(c.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 4, right: 8),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: Cores.textoSuave,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _renomear(c),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Renomear',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _renomear(c),
                          ),
                          IconButton(
                            tooltip: 'Excluir',
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: Cores.vinho,
                            onPressed: () => _excluir(c),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
