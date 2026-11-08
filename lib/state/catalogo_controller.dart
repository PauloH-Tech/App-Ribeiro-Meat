import 'package:flutter/foundation.dart';
import 'package:ribeiro_meat/models/categoria.dart';
import 'package:ribeiro_meat/models/configuracao_loja.dart';
import 'package:ribeiro_meat/services/catalogo_service.dart';

enum StatusCatalogo { carregando, pronto, erro }

class CatalogoController extends ChangeNotifier {
  StatusCatalogo status = StatusCatalogo.carregando;
  List<Categoria> categorias = [];
  ConfiguracaoLoja? configuracao;
  String? erro;

  Future<void> carregar() async {
    status = StatusCatalogo.carregando;
    erro = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        CatalogoService.listarCatalogo(),
        CatalogoService.buscarConfiguracao(),
      ]);
      categorias = resultados[0] as List<Categoria>;
      configuracao = resultados[1] as ConfiguracaoLoja;
      status = StatusCatalogo.pronto;
    } catch (e) {
      debugPrint('Erro ao carregar catálogo: $e');
      erro = 'Não foi possível carregar o catálogo.\n'
          'Verifique sua conexão e tente novamente.';
      status = StatusCatalogo.erro;
    }
    notifyListeners();
  }
}
