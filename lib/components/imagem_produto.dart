import 'package:flutter/material.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/produto.dart';

/// Foto do produto, com um placeholder elegante quando não há imagem.
class ImagemProduto extends StatelessWidget {
  final Produto produto;
  final double tamanhoIcone;

  const ImagemProduto({super.key, required this.produto, this.tamanhoIcone = 40});

  @override
  Widget build(BuildContext context) {
    if (!produto.temImagem) return _placeholder();
    return Image.network(
      produto.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progresso) =>
          progresso == null ? child : _placeholder(carregando: true),
    );
  }

  Widget _placeholder({bool carregando = false}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6E3D8), Color(0xFFEFCDBE)],
        ),
      ),
      child: Center(
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _icone,
                size: tamanhoIcone,
                color: Cores.vinho.withValues(alpha: 0.45),
              ),
      ),
    );
  }

  IconData get _icone => switch (produto.unitMeasurement) {
    UnitMeasurement.kg => Icons.kebab_dining_rounded,
    UnitMeasurement.peca => Icons.outdoor_grill_rounded,
    UnitMeasurement.pacote => Icons.inventory_2_rounded,
    UnitMeasurement.unidade => Icons.set_meal_rounded,
  };
}
