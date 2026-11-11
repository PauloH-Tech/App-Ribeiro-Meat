import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ribeiro_meat/config/tema.dart';
import 'package:ribeiro_meat/services/api_service.dart';
import 'package:ribeiro_meat/state/admin_auth.dart';

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  final _form = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  bool _mostrarSenha = false;
  bool _entrando = false;
  String? _erro;

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      await context.read<AdminAuth>().entrar(_usuario.text.trim(), _senha.text);
    } on ApiException catch (e) {
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar ao catálogo',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Cores.vinho.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 40,
                          color: Cores.vinho,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Área do administrador',
                      textAlign: TextAlign.center,
                      style: tema.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entre para gerenciar produtos e categorias.',
                      textAlign: TextAlign.center,
                      style: tema.bodyMedium?.copyWith(color: Cores.textoSuave),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _usuario,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Informe o usuário' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _senha,
                      obscureText: !_mostrarSenha,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _mostrarSenha ? 'Ocultar' : 'Mostrar',
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Informe a senha' : null,
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Cores.vinho.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Cores.vinho,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_erro!)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _entrando ? null : _entrar,
                      child: _entrando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
