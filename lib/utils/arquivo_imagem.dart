import 'dart:typed_data';

/// Regras das fotos de produto (as mesmas que a API valida).
class ArquivoImagem {
  static const tamanhoMaximo = 5 * 1024 * 1024;

  static const _extensoes = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  /// Descobre o tipo pelos primeiros bytes do arquivo (não confia no nome
  /// nem na extensão). null = formato não suportado.
  static String? tipo(Uint8List b) {
    bool comeca(int pos, List<int> assinatura) {
      if (b.length < pos + assinatura.length) return false;
      for (var i = 0; i < assinatura.length; i++) {
        if (b[pos + i] != assinatura[i]) return false;
      }
      return true;
    }

    if (comeca(0, [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (comeca(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }
    // "RIFF" .... "WEBP"
    if (comeca(0, [0x52, 0x49, 0x46, 0x46]) &&
        comeca(8, [0x57, 0x45, 0x42, 0x50])) {
      return 'image/webp';
    }
    return null;
  }

  static String extensao(String tipo) => _extensoes[tipo] ?? 'bin';
}
