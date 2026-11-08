import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/components/adicionar_produto_sheet.dart';
import 'package:ribeiro_meat/components/imagem_produto.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/models/produto.dart';
import 'package:ribeiro_meat/state/carrinho.dart';
import 'package:ribeiro_meat/utils/formatador.dart';

class ProdutoCard extends StatelessWidget {
  final Produto produto;
  const ProdutoCard({super.key, required this.produto});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final noCarrinho = context.select<Carrinho, double>(
      (c) => c.quantidadeDoProduto(produto.id),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: noCarrinho > 0 ? Cores.vinho.withValues(alpha: 0.5) : Cores.borda,
          width: noCarrinho > 0 ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => AdicionarProdutoSheet.abrir(context, produto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImagemProduto(produto: produto),
                  if (noCarrinho > 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Selo(
                        texto: Formatador.quantidade(
                          noCarrinho,
                          produto.unitMeasurement,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 34,
                    child: Text(
                      produto.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.bodySmall?.copyWith(
                        color: Cores.textoSuave,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          produto.unitMeasurement.rotulo,
                          style: tema.labelMedium?.copyWith(
                            color: Cores.vinho,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Material(
                        color: noCarrinho > 0 ? Cores.vinhoEscuro : Cores.vinho,
                        shape: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  final String texto;
  const _Selo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Cores.vinho,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
