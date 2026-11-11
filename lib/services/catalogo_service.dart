import 'package:ribeiro_meat/models/categoria.dart';
import 'package:ribeiro_meat/models/configuracao_loja.dart';
import 'package:ribeiro_meat/services/api_service.dart';

class CatalogoService {
  static Future<List<Categoria>> listarCatalogo() async {
    final data = await ApiService.get('/v1/catalogos');
    return (data as List)
        .map((j) => Categoria.fromJson(j))
        .where((c) => c.products.isNotEmpty)
        .toList();
  }

  static Future<ConfiguracaoLoja> buscarConfiguracao() async {
    final data = await ApiService.get('/v1/configuracoes');
    return ConfiguracaoLoja.fromJson(data as Map<String, dynamic>);
  }
}
