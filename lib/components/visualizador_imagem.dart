import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/produto.dart';

class VisualizadorImagem extends StatelessWidget {
  final Produto produto;
  const new({super.key, required this.produto});

  static String heroTag(Produto produto) => 'imagem-produto-${produto.id}';

  static Future<void> abrir(BuildContext context, Produto produto) async {
    if (!produto.temImagem) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => VisualizadorImagem(produto: produto),
        transitionsBuilder: (_, animacao, _, child) =>
            FadeTransition(opacity: animacao, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          produto.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: SizedBox.expand(
          child: Hero(
            tag: heroTag(produto),
            child: Image.network(
              produto.imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 64,
                  color: Cores.vinho.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
