import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ribeiro_meat/config/app_config.dart';
import 'package:ribeiro_meat/utils/erro_resposta.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 15);

  /// Token JWT do administrador (definido pelo AdminAuth após o login).
  static String? token;

  /// Chamado quando a API responde 401 (token expirado/inválido).
  static void Function()? onNaoAutorizado;

  static Map<String, String> _headers({bool json = false}) => {
    if (json) 'Content-Type': 'application/json; charset=utf-8',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Uri _uri(String path) => Uri.parse('${AppConfig.apiUrl}$path');

  static Future<dynamic> get(String path) =>
      _executar(() => http.get(_uri(path), headers: _headers()));

  static Future<dynamic> post(String path, Object? body) => _executar(
    () => http.post(
      _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    ),
  );

  static Future<dynamic> put(String path, Object? body) => _executar(
    () => http.put(
      _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    ),
  );

  static Future<dynamic> patch(String path, Object? body) => _executar(
    () => http.patch(
      _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    ),
  );

  static Future<dynamic> delete(String path) =>
      _executar(() => http.delete(_uri(path), headers: _headers()));

  static Future<dynamic> _executar(Future<http.Response> Function() req) async {
    final http.Response res;
    try {
      res = await req().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'O servidor demorou para responder. Tente novamente.');
    } catch (_) {
      throw ApiException(0, 'Sem conexão com o servidor.');
    }
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    if (res.statusCode == 401 && token != null) {
      onNaoAutorizado?.call();
    }
    String? mensagem;
    try {
      final erro = ErroResposta.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      mensagem = erro.message;
    } catch (_) {}
    if (mensagem == null || mensagem.isEmpty) {
      mensagem = switch (res.statusCode) {
        401 => 'Sessão expirada. Entre novamente.',
        403 => 'Acesso negado.',
        404 => 'Registro não encontrado.',
        _ => 'Erro inesperado (${res.statusCode}).',
      };
    }
    throw ApiException(res.statusCode, mensagem);
  }
}
