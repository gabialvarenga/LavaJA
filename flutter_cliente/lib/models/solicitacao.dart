enum StatusSolicitacao {
  pendente,
  aceita,
  recusada,
  emExecucao,
  concluida,
  cancelada,
}

extension StatusSolicitacaoX on StatusSolicitacao {
  static StatusSolicitacao fromString(String value) {
    switch (value) {
      case 'aceita':
        return StatusSolicitacao.aceita;
      case 'recusada':
        return StatusSolicitacao.recusada;
      case 'em_execucao':
        return StatusSolicitacao.emExecucao;
      case 'concluida':
        return StatusSolicitacao.concluida;
      case 'cancelada':
        return StatusSolicitacao.cancelada;
      default:
        return StatusSolicitacao.pendente;
    }
  }

  String get label {
    switch (this) {
      case StatusSolicitacao.pendente:
        return 'pendente';
      case StatusSolicitacao.aceita:
        return 'aceita';
      case StatusSolicitacao.recusada:
        return 'recusada';
      case StatusSolicitacao.emExecucao:
        return 'em execução';
      case StatusSolicitacao.concluida:
        return 'concluída';
      case StatusSolicitacao.cancelada:
        return 'cancelada';
    }
  }

  bool get podeSerCancelada =>
      this == StatusSolicitacao.pendente || this == StatusSolicitacao.aceita;

  bool get isAtiva =>
      this == StatusSolicitacao.pendente ||
      this == StatusSolicitacao.aceita ||
      this == StatusSolicitacao.emExecucao;
}

enum TipoServico { simples, completa, polimento }

extension TipoServicoX on TipoServico {
  static TipoServico fromString(String value) {
    switch (value) {
      case 'completa':
        return TipoServico.completa;
      case 'polimento':
        return TipoServico.polimento;
      default:
        return TipoServico.simples;
    }
  }

  String get value {
    switch (this) {
      case TipoServico.simples:
        return 'simples';
      case TipoServico.completa:
        return 'completa';
      case TipoServico.polimento:
        return 'polimento';
    }
  }

  String get label {
    switch (this) {
      case TipoServico.simples:
        return 'Simples';
      case TipoServico.completa:
        return 'Completa';
      case TipoServico.polimento:
        return 'Polimento';
    }
  }

  String get descricao {
    switch (this) {
      case TipoServico.simples:
        return 'Lavagem externa do veículo';
      case TipoServico.completa:
        return 'Lavagem externa, interna e aspiração';
      case TipoServico.polimento:
        return 'Polimento completo da lataria';
    }
  }
}

class HistoricoStatus {
  final String id;
  final String solicitacaoId;
  final String? statusAnterior;
  final String statusNovo;
  final String alteradoPorNome;
  final String criadoEm;

  const HistoricoStatus({
    required this.id,
    required this.solicitacaoId,
    this.statusAnterior,
    required this.statusNovo,
    required this.alteradoPorNome,
    required this.criadoEm,
  });

  factory HistoricoStatus.fromJson(Map<String, dynamic> json) =>
      HistoricoStatus(
        id: json['id'] as String,
        solicitacaoId: json['solicitacao_id'] as String,
        statusAnterior: json['status_anterior'] as String?,
        statusNovo: json['status_novo'] as String,
        alteradoPorNome: json['alterado_por_nome'] as String? ?? '',
        criadoEm: json['criado_em'] as String,
      );
}

class Solicitacao {
  final String id;
  final String clienteId;
  final String? lavadorId;
  final String veiculoId;
  final String endereco;
  final TipoServico tipoServico;
  final StatusSolicitacao status;
  final String? observacoes;
  final String criadoEm;
  final String atualizadoEm;

  // Campos do JOIN
  final String? clienteNome;
  final String? placa;
  final String? modelo;

  // Histórico incluído no GET :id
  final List<HistoricoStatus> historico;

  const Solicitacao({
    required this.id,
    required this.clienteId,
    this.lavadorId,
    required this.veiculoId,
    required this.endereco,
    required this.tipoServico,
    required this.status,
    this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
    this.clienteNome,
    this.placa,
    this.modelo,
    this.historico = const [],
  });

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    final historicoRaw = json['historico'];
    final historico = historicoRaw is List
        ? historicoRaw
            .map((h) => HistoricoStatus.fromJson(h as Map<String, dynamic>))
            .toList()
        : <HistoricoStatus>[];

    return Solicitacao(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      lavadorId: json['lavador_id'] as String?,
      veiculoId: json['veiculo_id'] as String,
      endereco: json['endereco'] as String,
      tipoServico:
          TipoServicoX.fromString(json['tipo_servico'] as String? ?? ''),
      status: StatusSolicitacaoX.fromString(json['status'] as String? ?? ''),
      observacoes: json['observacoes'] as String?,
      criadoEm: json['criado_em'] as String,
      atualizadoEm: json['atualizado_em'] as String,
      clienteNome: json['cliente_nome'] as String?,
      placa: json['placa'] as String?,
      modelo: json['modelo'] as String?,
      historico: historico,
    );
  }

  String get veiculoDisplay =>
      modelo != null && placa != null ? '$modelo · $placa' : veiculoId;

  Solicitacao copyWithStatus(StatusSolicitacao novoStatus) => Solicitacao(
        id: id,
        clienteId: clienteId,
        lavadorId: lavadorId,
        veiculoId: veiculoId,
        endereco: endereco,
        tipoServico: tipoServico,
        status: novoStatus,
        observacoes: observacoes,
        criadoEm: criadoEm,
        atualizadoEm: atualizadoEm,
        clienteNome: clienteNome,
        placa: placa,
        modelo: modelo,
        historico: historico,
      );
}
