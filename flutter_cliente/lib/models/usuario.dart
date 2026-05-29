class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String tipo;
  final String criadoEm;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.tipo,
    required this.criadoEm,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        telefone: json['telefone'] as String,
        tipo: json['tipo'] as String,
        criadoEm: json['criado_em'] as String,
      );
}
