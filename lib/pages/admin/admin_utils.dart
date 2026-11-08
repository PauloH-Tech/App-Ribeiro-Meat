import 'package:flutter/material.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/services/api_service.dart';

void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: erro ? Cores.vinhoEscuro : Cores.texto,
        content: Row(
          children: [
            Icon(
              erro ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: erro ? Colors.white : Cores.dourado,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
}

/// Executa uma chamada à API mostrando erro/sucesso. Retorna true se deu certo.
Future<bool> executarAcao(
  BuildContext context,
  Future<void> Function() acao, {
  String? sucesso,
}) async {
  try {
    await acao();
    if (sucesso != null && context.mounted) mostrarMensagem(context, sucesso);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) mostrarMensagem(context, e.message, erro: true);
  } catch (e) {
    if (context.mounted) {
      mostrarMensagem(context, 'Erro inesperado: $e', erro: true);
    }
  }
  return false;
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String acao = 'Excluir',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(acao),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Diálogo com um campo de texto. Retorna o texto ou null se cancelado.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String rotulo,
  String inicial = '',
  int maxLength = 60,
}) {
  final controller = TextEditingController(text: inicial);
  final form = GlobalKey<FormState>();
  void salvar(BuildContext ctx) {
    if (form.currentState!.validate()) {
      Navigator.pop(ctx, controller.text.trim());
    }
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Form(
        key: form,
        child: SizedBox(
          width: 360,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: rotulo),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Campo obrigatório' : null,
            onFieldSubmitted: (_) => salvar(ctx),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => salvar(ctx),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

/// Centraliza o conteúdo com largura máxima (telas grandes).
EdgeInsets paddingResponsivo(BuildContext context, {double max = 900}) {
  final largura = MediaQuery.sizeOf(context).width;
  final lateral = ((largura - max) / 2).clamp(16.0, double.infinity);
  return EdgeInsets.fromLTRB(lateral, 12, lateral, 100);
}
