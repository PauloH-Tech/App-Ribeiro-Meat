import 'package:ribeiro_meat/models/admin.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/services/api_service.dart';

/// Chamadas da área administrativa (exigem token).
class AdminService {
  // ---------- Autenticação ----------
  static Future<Map<String, dynamic>> login(String usuario, String senha) async {
    final data = await ApiService.post('/v1/auth/login', {
      'usuario': usuario,
      'senha': senha,
    });
    return data as Map<String, dynamic>;
  }

  // ---------- Categorias ----------
  static const _categorias = '/v1/admin/categorias';

  static Future<List<CategoriaAdmin>> listarCategorias() async {
    final data = await ApiService.get(_categorias) as List;
    return data.map((j) => CategoriaAdmin.fromJson(j)).toList();
  }

  static Future<void> salvarCategoria({
    int? id,
    required String nome,
    required int ordem,
  }) {
    final body = {'name': nome.trim(), 'displayOrder': ordem};
    return id == null
        ? ApiService.post(_categorias, body)
        : ApiService.put('$_categorias/$id', body);
  }

  static Future<void> excluirCategoria(int id) =>
      ApiService.delete('$_categorias/$id');

  // ---------- Opções de preparo ----------
  static const _preparos = '/v1/admin/opcoes-preparo';

  static Future<List<OpcaoPreparo>> listarPreparos() async {
    final data = await ApiService.get(_preparos) as List;
    return data.map((j) => OpcaoPreparo.fromJson(j)).toList();
  }

  static Future<void> salvarPreparo({int? id, required String nome}) {
    final body = {'name': nome.trim()};
    return id == null
        ? ApiService.post(_preparos, body)
        : ApiService.put('$_preparos/$id', body);
  }

  static Future<void> excluirPreparo(int id) =>
      ApiService.delete('$_preparos/$id');

  // ---------- Produtos ----------
  static const _produtos = '/v1/admin/produtos';

  static Future<List<ProdutoAdmin>> listarProdutos() async {
    final data = await ApiService.get(_produtos) as List;
    final lista = data.map((j) => ProdutoAdmin.fromJson(j)).toList();
    lista.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return lista;
  }

  static Future<void> salvarProduto({int? id, required ProdutoForm form}) =>
      id == null
      ? ApiService.post(_produtos, form.toJson())
      : ApiService.put('$_produtos/$id', form.toJson());

  static Future<void> alterarDisponibilidade(int id, bool disponivel) =>
      ApiService.patch('$_produtos/$id/disponibilidade', {
        'available': disponivel,
      });

  static Future<void> excluirProduto(int id) =>
      ApiService.delete('$_produtos/$id');
}
