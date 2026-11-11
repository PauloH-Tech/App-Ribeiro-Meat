import 'package:flutter/foundation.dart';
import 'package:ribeiro_meat/services/admin_service.dart';
import 'package:ribeiro_meat/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sessão do administrador. O token fica salvo no dispositivo até expirar
/// ou até o administrador sair.
class AdminAuth extends ChangeNotifier {
  static const _kToken = 'admin_token';
  static const _kExpira = 'admin_expira';
  static const _kUsuario = 'admin_usuario';

  String? _token;
  DateTime? _expiraEm;
  String? usuario;
  bool carregado = false;

  bool get logado =>
      _token != null &&
      _expiraEm != null &&
      _expiraEm!.isAfter(DateTime.now());

  AdminAuth() {
    ApiService.onNaoAutorizado = () => sair();
  }

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_kToken);
      final exp = prefs.getString(_kExpira);
      _expiraEm = exp == null ? null : DateTime.tryParse(exp);
      usuario = prefs.getString(_kUsuario);
      if (!logado) await _limpar(prefs);
    } catch (e) {
      debugPrint('Falha ao carregar sessão admin: $e');
    }
    ApiService.token = logado ? _token : null;
    carregado = true;
    notifyListeners();
  }

  Future<void> entrar(String usuario, String senha) async {
    final res = await AdminService.login(usuario, senha);
    _token = res['token'] as String;
    _expiraEm = DateTime.parse(res['expiraEm'] as String);
    this.usuario = res['usuario'] as String?;
    ApiService.token = _token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, _token!);
      await prefs.setString(_kExpira, _expiraEm!.toIso8601String());
      if (this.usuario != null) await prefs.setString(_kUsuario, this.usuario!);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> sair() async {
    if (_token == null) return;
    try {
      await _limpar(await SharedPreferences.getInstance());
    } catch (_) {
      _token = null;
      _expiraEm = null;
    }
    ApiService.token = null;
    notifyListeners();
  }

  Future<void> _limpar(SharedPreferences prefs) async {
    _token = null;
    _expiraEm = null;
    await prefs.remove(_kToken);
    await prefs.remove(_kExpira);
  }
}
