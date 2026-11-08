class ErroResposta {
  final int status;
  final String? message;

  ErroResposta({required this.status, this.message});

  factory ErroResposta.fromJson(Map<String, dynamic> json) {
    return ErroResposta(
      status: (json['status'] as num?)?.toInt() ?? 0,
      // Spring envia o texto em "message" (pode vir vazio).
      message: (json['message'] as String?)?.trim().isNotEmpty == true
          ? json['message'] as String
          : null,
    );
  }
}
