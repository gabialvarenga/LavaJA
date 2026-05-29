class Veiculo {
  final String id;
  final String usuarioId;
  final String placa;
  final String modelo;
  final String? cor;
  final String criadoEm;

  const Veiculo({
    required this.id,
    required this.usuarioId,
    required this.placa,
    required this.modelo,
    this.cor,
    required this.criadoEm,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) => Veiculo(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        placa: json['placa'] as String,
        modelo: json['modelo'] as String,
        cor: json['cor'] as String?,
        criadoEm: json['criado_em'] as String,
      );

  String get displayName => cor != null ? '$modelo · $cor · $placa' : '$modelo · $placa';
  String get shortName => '$modelo · $placa';
}
