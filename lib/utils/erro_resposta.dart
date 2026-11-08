class ErroResposta {
  final int status;
  final String message;

  ErroResposta({required this.status, required this.message});

  factory ErroResposta.fromJson(Map<String, dynamic> json) {
    return ErroResposta(status: json['status'], message: json['message']);
  }
}
