import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ribeiro_meat/models/categoria.dart';
import 'package:ribeiro_meat/models/item_carrinho.dart';
import 'package:ribeiro_meat/models/opcao_preparo.dart';
import 'package:ribeiro_meat/models/produto.dart';
import 'package:ribeiro_meat/utils/formatador.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carrinho do cliente. É salvo no dispositivo para não se perder ao
/// recarregar a página.
class Carrinho extends ChangeNotifier {
  static const _chaveStorage = 'carrinho_v1';

  final List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  bool get vazio => _itens.isEmpty;
  int get totalItens => _itens.length;

  /// Quantidade total (somada) de um produto no carrinho.
  double quantidadeDoProduto(int produtoId) => _itens
      .where((i) => i.produto.id == produtoId)
      .fold(0.0, (soma, i) => soma + i.quantidade);

  bool contem(int produtoId) => _itens.any((i) => i.produto.id == produtoId);

  List<Categoria> _catalogo = const [];

  /// Troca o produto salvo em cada item pela versão atual do catálogo, para
  /// que preço e demais dados não fiquem desatualizados no carrinho salvo.
  void sincronizar(List<Categoria> categorias) {
    _catalogo = categorias;
    if (_aplicarCatalogo()) _mudou();
  }

  bool _aplicarCatalogo() {
    if (_catalogo.isEmpty) return false;
    final atuais = {
      for (final c in _catalogo)
        for (final p in c.products) p.id: p,
    };
    var mudou = false;
    for (var i = 0; i < _itens.length; i++) {
      final novo = atuais[_itens[i].produto.id];
      if (novo != null && !identical(novo, _itens[i].produto)) {
        _itens[i] = _itens[i].copyWith(produto: novo);
        mudou = true;
      }
    }
    return mudou;
  }

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_chaveStorage);
      if (json == null) return;
      final lista = jsonDecode(json) as List;
      _itens
        ..clear()
        ..addAll(lista.map((j) => ItemCarrinho.fromJson(j)));
      // O catálogo pode ter carregado antes do carrinho salvo.
      _aplicarCatalogo() ? _mudou() : notifyListeners();
    } catch (e) {
      debugPrint('Falha ao carregar carrinho: $e');
    }
  }

  Future<void> _salvar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chaveStorage,
        jsonEncode(_itens.map((i) => i.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Falha ao salvar carrinho: $e');
    }
  }

  void _mudou() {
    notifyListeners();
    _salvar();
  }

  void adicionar(
    Produto produto,
    double quantidade, {
    OpcaoPreparo? preparo,
    String observacao = '',
  }) {
    final novo = ItemCarrinho(
      produto: produto,
      quantidade: Formatador.arredondar(quantidade),
      preparo: preparo,
      observacao: observacao.trim(),
    );
    final idx = _itens.indexWhere((i) => i.chave == novo.chave);
    if (idx >= 0) {
      _itens[idx] = _itens[idx].copyWith(
        quantidade: Formatador.arredondar(_itens[idx].quantidade + quantidade),
      );
    } else {
      _itens.add(novo);
    }
    _mudou();
  }

  /// Substitui um item (usado na edição).
  void substituir(ItemCarrinho antigo, ItemCarrinho novo) {
    final idx = _itens.indexOf(antigo);
    if (idx < 0) return;
    _itens.removeAt(idx);
    // Se já existe um item igual, soma; senão reinsere na mesma posição.
    final igual = _itens.indexWhere((i) => i.chave == novo.chave);
    if (igual >= 0) {
      _itens[igual] = _itens[igual].copyWith(
        quantidade: Formatador.arredondar(
          _itens[igual].quantidade + novo.quantidade,
        ),
      );
    } else {
      _itens.insert(idx, novo);
    }
    _mudou();
  }

  void incrementar(ItemCarrinho item) {
    final idx = _itens.indexOf(item);
    if (idx < 0) return;
    _itens[idx] = item.copyWith(
      quantidade: Formatador.arredondar(
        item.quantidade + item.produto.increment,
      ),
    );
    _mudou();
  }

  /// Diminui a quantidade; retorna false se já está no mínimo.
  bool decrementar(ItemCarrinho item) {
    final idx = _itens.indexOf(item);
    if (idx < 0) return false;
    final nova = Formatador.arredondar(
      item.quantidade - item.produto.increment,
    );
    if (nova < item.produto.minQuantity - 0.0001) return false;
    _itens[idx] = item.copyWith(quantidade: nova);
    _mudou();
    return true;
  }

  void remover(ItemCarrinho item) {
    _itens.remove(item);
    _mudou();
  }

  void inserir(int posicao, ItemCarrinho item) {
    _itens.insert(posicao.clamp(0, _itens.length), item);
    _mudou();
  }

  void limpar() {
    _itens.clear();
    _mudou();
  }
}
