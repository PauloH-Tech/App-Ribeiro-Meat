import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/pages/admin/categorias_admin_tab.dart';
import 'package:ribeiro_meat/pages/admin/login_admin_page.dart';
import 'package:ribeiro_meat/pages/admin/preparos_admin_tab.dart';
import 'package:ribeiro_meat/pages/admin/produtos_admin_tab.dart';
import 'package:ribeiro_meat/state/admin_auth.dart';
import 'package:ribeiro_meat/state/catalogo_controller.dart';

/// Entrada da área administrativa (rota /admin).
/// Mostra o login ou o painel, conforme a sessão.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuth>();
    if (!auth.carregado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.logado ? const _Painel() : const LoginAdminPage();
  }
}

class _Painel extends StatefulWidget {
  const _Painel();

  @override
  State<_Painel> createState() => _PainelState();
}

class _PainelState extends State<_Painel> {
  int _aba = 0;
  late final CatalogoController _catalogo;

  static const _abas = [
    (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Produtos'),
    (Icons.category_outlined, Icons.category_rounded, 'Categorias'),
    (Icons.restaurant_outlined, Icons.restaurant_rounded, 'Preparos'),
  ];

  @override
  void initState() {
    super.initState();
    _catalogo = context.read<CatalogoController>();
  }

  @override
  void dispose() {
    // Ao sair do painel, o catálogo público reflete as alterações.
    _catalogo.carregar();
    super.dispose();
  }

  Future<void> _sair() async {
    await context.read<AdminAuth>().sair();
  }

  @override
  Widget build(BuildContext context) {
    final largo = MediaQuery.sizeOf(context).width >= 840;
    final usuario = context.select<AdminAuth, String?>((a) => a.usuario);

    // Cada aba recarrega ao ser aberta, refletindo mudanças feitas nas outras.
    final conteudo = switch (_aba) {
      0 => const ProdutosAdminTab(),
      1 => const CategoriasAdminTab(),
      _ => const PreparosAdminTab(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Cores.vinho,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Painel'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (_) => false),
            icon: const Icon(Icons.storefront_outlined),
            label: Text(largo ? 'Ver catálogo' : 'Catálogo'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Conta',
            icon: const Icon(Icons.account_circle_outlined),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('Conectado como ${usuario ?? 'admin'}'),
              ),
              const PopupMenuItem(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'sair') _sair();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: largo
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _aba,
                  onDestinationSelected: (i) => setState(() => _aba = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Cores.fundo,
                  destinations: [
                    for (final a in _abas)
                      NavigationRailDestination(
                        icon: Icon(a.$1),
                        selectedIcon: Icon(a.$2),
                        label: Text(a.$3),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: Cores.borda),
                Expanded(child: conteudo),
              ],
            )
          : conteudo,
      bottomNavigationBar: largo
          ? null
          : NavigationBar(
              selectedIndex: _aba,
              onDestinationSelected: (i) => setState(() => _aba = i),
              backgroundColor: Cores.superficie,
              destinations: [
                for (final a in _abas)
                  NavigationDestination(
                    icon: Icon(a.$1),
                    selectedIcon: Icon(a.$2),
                    label: a.$3,
                  ),
              ],
            ),
    );
  }
}
