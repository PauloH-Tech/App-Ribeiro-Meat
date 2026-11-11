import 'package:flutter/material.dart';
import 'package:ribeiro_meat/config/tema.dart';

/// Tela/área de mensagem (vazio, erro...) com ícone e ação opcional.
class EstadoMensagem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? mensagem;
  final String? textoAcao;
  final VoidCallback? onAcao;

  const EstadoMensagem({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.textoAcao,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Cores.vinho.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 44, color: Cores.vinho),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: tema.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (mensagem != null) ...[
                const SizedBox(height: 8),
                Text(
                  mensagem!,
                  textAlign: TextAlign.center,
                  style: tema.bodyMedium?.copyWith(color: Cores.textoSuave),
                ),
              ],
              if (textoAcao != null && onAcao != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAcao,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: Text(textoAcao!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
