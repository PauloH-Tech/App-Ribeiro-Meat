import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/pages/carrinho_page.dart';
import 'package:ribeiro_meat/state/carrinho.dart';

/// Barra flutuante "Ver pedido" exibida quando há itens no carrinho.
class BarraCarrinho extends StatelessWidget {
  const BarraCarrinho({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.select<Carrinho, int>((c) => c.totalItens);
    final largura = MediaQuery.sizeOf(context).width;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: child,
      ),
      child: total == 0
          ? const SizedBox.shrink()
          : SizedBox(
              key: const ValueKey('barra'),
              width: (largura - 32).clamp(0, 520),
              child: Material(
                color: Cores.vinho,
                elevation: 8,
                shadowColor: Cores.vinho.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CarrinhoPage()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            total == 1 ? '1 item no pedido' : '$total itens no pedido',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Text(
                          'Ver pedido',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
