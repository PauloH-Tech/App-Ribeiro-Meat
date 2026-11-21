import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/state/catalogo_controller.dart';

/// Imita o painel admin: recarrega o catálogo no dispose.
class _RecarregaAoSair extends StatefulWidget {
  final bool silencioso;
  const _RecarregaAoSair({required this.silencioso});

  @override
  State<_RecarregaAoSair> createState() => _RecarregaAoSairState();
}

class _RecarregaAoSairState extends State<_RecarregaAoSair> {
  late final CatalogoController _catalogo;

  @override
  void initState() {
    super.initState();
    _catalogo = context.read<CatalogoController>();
  }

  @override
  void dispose() {
    _catalogo.carregar(silencioso: widget.silencioso);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

Widget _app(CatalogoController catalogo, {required bool comPainel}) =>
    ChangeNotifierProvider.value(
      value: catalogo,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            // Alguém observando o catálogo (como a HomePage).
            context.watch<CatalogoController>();
            return comPainel
                ? const _RecarregaAoSair(silencioso: true)
                : const SizedBox();
          },
        ),
      ),
    );

void main() {
  testWidgets('sair do admin recarrega o catálogo sem erro de build', (
    tester,
  ) async {
    final catalogo = CatalogoController()..status = StatusCatalogo.pronto;

    await tester.pumpWidget(_app(catalogo, comPainel: true));
    await tester.pumpWidget(_app(catalogo, comPainel: false)); // dispose
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('carregar silencioso não mostra "carregando"', () {
    final catalogo = CatalogoController()..status = StatusCatalogo.pronto;
    var notificou = false;
    catalogo.addListener(() => notificou = true);

    catalogo.carregar(silencioso: true); // sem await: só a parte síncrona

    expect(catalogo.status, StatusCatalogo.pronto);
    expect(notificou, isFalse);
  });
}
