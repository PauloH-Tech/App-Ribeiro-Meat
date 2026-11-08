import 'package:flutter/material.dart';
import 'package:ribeiro_meat/config/tema.dart';

/// Controle "−  1,5 kg  +".
class SeletorQuantidade extends StatelessWidget {
  final String valor;
  final VoidCallback? onMenos;
  final VoidCallback? onMais;
  final bool compacto;

  const SeletorQuantidade({
    super.key,
    required this.valor,
    required this.onMenos,
    required this.onMais,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final tamanho = compacto ? 34.0 : 48.0;
    final estilo = compacto
        ? Theme.of(context).textTheme.labelLarge
        : Theme.of(context).textTheme.titleLarge;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Botao(
            icone: Icons.remove_rounded,
            tamanho: tamanho,
            onTap: onMenos,
            tooltip: 'Diminuir',
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: compacto ? 64 : 110),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                valor,
                key: ValueKey(valor),
                textAlign: TextAlign.center,
                style: estilo?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _Botao(
            icone: Icons.add_rounded,
            tamanho: tamanho,
            onTap: onMais,
            tooltip: 'Aumentar',
            destaque: true,
          ),
        ],
      ),
    );
  }
}

class _Botao extends StatelessWidget {
  final IconData icone;
  final double tamanho;
  final VoidCallback? onTap;
  final String tooltip;
  final bool destaque;

  const _Botao({
    required this.icone,
    required this.tamanho,
    required this.onTap,
    required this.tooltip,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: !ativo
            ? Colors.transparent
            : destaque
            ? Cores.vinho
            : Cores.superficie,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: tamanho,
            height: tamanho,
            child: Icon(
              icone,
              size: tamanho * 0.5,
              color: !ativo
                  ? Cores.textoSuave.withValues(alpha: 0.4)
                  : destaque
                  ? Colors.white
                  : Cores.texto,
            ),
          ),
        ),
      ),
    );
  }
}
