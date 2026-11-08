import 'package:flutter/material.dart';
import 'package:ribeiro_meat/components/estado_mensagem.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/pages/admin/admin_utils.dart';
import 'package:ribeiro_meat/services/admin_service.dart';
import 'package:ribeiro_meat/services/api_service.dart';

class PreparosAdminTab extends StatefulWidget {
  const PreparosAdminTab({super.key});

  @override
  State<PreparosAdminTab> createState() => _PreparosAdminTabState();
}

class _PreparosAdminTabState extends State<PreparosAdminTab> {
  List<OpcaoPreparo> _preparos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final lista = await AdminService.listarPreparos();
      if (mounted) setState(() => _preparos = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editar([OpcaoPreparo? o]) async {
    final nome = await pedirTexto(
      context,
      titulo: o == null ? 'Nova opção de preparo' : 'Renomear opção',
      rotulo: 'Nome (ex.: Moída, Bife, Cubos)',
      inicial: o?.name ?? '',
    );
    if (nome == null || nome == o?.name || !mounted) return;
    final ok = await executarAcao(
      context,
      () => AdminService.salvarPreparo(id: o?.id, nome: nome),
      sucesso: o == null ? 'Opção criada' : 'Opção atualizada',
    );
    if (ok) _carregar();
  }

  Future<void> _excluir(OpcaoPreparo o) async {
    final sim = await confirmar(
      context,
      titulo: 'Excluir "${o.name}"?',
      mensagem: 'Ela deixará de aparecer em todos os produtos que a usam.',
    );
    if (!sim || !mounted) return;
    final ok = await executarAcao(
      context,
      () => AdminService.excluirPreparo(o.id),
      sucesso: 'Opção excluída',
    );
    if (ok) _carregar();
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

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        backgroundColor: Cores.vinho,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova opção'),
      ),
      body: _preparos.isEmpty
          ? const EstadoMensagem(
              icone: Icons.restaurant_outlined,
              titulo: 'Nenhuma opção de preparo',
              mensagem: 'Ex.: Moída, Bife, Cubos, Tiras, Peça inteira.',
            )
          : ListView(
              padding: paddingResponsivo(context, max: 720),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Formas de preparo que o cliente pode escolher. '
                    'Associe-as aos produtos na tela de cada produto.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Cores.textoSuave),
                  ),
                ),
                for (final o in _preparos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.restaurant_rounded,
                          color: Cores.vinho,
                        ),
                        title: Text(
                          o.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _editar(o),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Renomear',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editar(o),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: Cores.vinho,
                              onPressed: () => _excluir(o),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
