class OpcaoPreparo {
  final int id;
  final String name;

  const OpcaoPreparo({required this.id, required this.name});

  factory OpcaoPreparo.fromJson(Map<String, dynamic> j) =>
      OpcaoPreparo(id: j['id'], name: j['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is OpcaoPreparo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
