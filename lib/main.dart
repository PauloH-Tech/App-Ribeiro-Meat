import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/pages/admin/admin_page.dart';
import 'package:ribeiro_meat/pages/home_page.dart';
import 'package:ribeiro_meat/state/admin_auth.dart';
import 'package:ribeiro_meat/state/carrinho.dart';
import 'package:ribeiro_meat/state/catalogo_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Carrinho()..carregar()),
        ChangeNotifierProvider(
          create: (ctx) {
            final catalogo = CatalogoController();
            // Mantém preços/dados dos itens do carrinho iguais ao catálogo.
            catalogo.addListener(() {
              if (catalogo.status == StatusCatalogo.pronto) {
                ctx.read<Carrinho>().sincronizar(catalogo.categorias);
              }
            });
            return catalogo..carregar();
          },
        ),
        ChangeNotifierProvider(create: (_) => AdminAuth()..carregar()),
      ],
      child: MaterialApp(
        title: 'Casa de Carnes Ribeiro',
        debugShowCheckedModeBanner: false,
        theme: Tema.claro,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Área administrativa: acessível pelo endereço .../#/admin
        routes: {
          '/': (_) => const HomePage(),
          '/admin': (_) => const AdminPage(),
        },
      ),
    );
  }
}
