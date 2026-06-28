import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/formatters/date_formatter.dart';
import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';
import '../services/websocket_service.dart';
import '../widgets/status_tag.dart';
import '../widgets/timeline_item.dart';

class DetalhesSolicitacaoScreen extends StatefulWidget {
  final String solicitacaoId;

  const DetalhesSolicitacaoScreen({Key? key, required this.solicitacaoId})
      : super(key: key);

  @override
  State<DetalhesSolicitacaoScreen> createState() =>
      _DetalhesSolicitacaoScreenState();
}

class _DetalhesSolicitacaoScreenState
    extends State<DetalhesSolicitacaoScreen> {
  Solicitacao? _solicitacao;
  bool _carregando = true;
  bool _processando = false;
  String? _erro;
  WsEvent? _wsEventoAnterior;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final evento = context.watch<WebSocketService>().ultimoEvento;
    if (evento != null && evento != _wsEventoAnterior) {
      _wsEventoAnterior = evento;
      final id = evento.dados['id'] as String?;
      if (id == widget.solicitacaoId) {
        _carregar();
      }
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _solicitacao == null;
      _erro = null;
    });
    try {
      final s = await SolicitacaoService.buscarPorId(widget.solicitacaoId);
      setState(() {
        _solicitacao = s;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  Future<void> _executarAcao(Future<Solicitacao> Function() acao) async {
    setState(() {
      _processando = true;
      _erro = null;
    });
    try {
      final atualizada = await acao();
      setState(() {
        _solicitacao = atualizada;
        _processando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _processando = false;
      });
    }
  }

  Future<void> _confirmarEAceitar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceitar solicitação'),
        content: const Text('Deseja aceitar esta solicitação de lavagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceitar',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _executarAcao(
          () => SolicitacaoService.aceitar(widget.solicitacaoId));
    }
  }

  Future<void> _confirmarERecusar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar solicitação'),
        content: const Text('Tem certeza que deseja recusar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recusar',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _executarAcao(
          () => SolicitacaoService.recusar(widget.solicitacaoId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTertiary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Detalhes',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _erro != null && _solicitacao == null
              ? _buildErro()
              : _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    final s = _solicitacao!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Cabeçalho — dados da solicitação
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.tipoServico.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusTag(status: s.status),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfo('Cliente', s.clienteNome ?? '—'),
                _buildInfo('Veículo', s.veiculoDisplay),
                _buildInfo('Endereço', s.endereco),
                _buildInfo('Serviço', '${s.tipoServico.label} · ${s.tipoServico.preco}'),
                if (s.observacoes != null && s.observacoes!.isNotEmpty)
                  _buildInfo('Obs.', s.observacoes!),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Timeline de histórico
          _buildCard(
            titulo: 'Acompanhamento',
            child: Column(children: _buildTimelineItems(s)),
          ),

          const SizedBox(height: 8),

          // Ações do lavador — condicionais ao status
          if (s.status == StatusSolicitacao.pendente)
            _buildAcoesPendente()
          else if (s.status == StatusSolicitacao.aceita)
            _buildCard(
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _processando
                      ? null
                      : () => _executarAcao(
                          () => SolicitacaoService.iniciar(widget.solicitacaoId)),
                  icon: _processando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_circle_outline,
                          size: 18, color: Colors.white),
                  label: const Text('Iniciar lavagem',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            )
          else if (s.status == StatusSolicitacao.emExecucao)
            _buildCard(
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _processando
                      ? null
                      : () => _executarAcao(
                          () => SolicitacaoService.concluir(widget.solicitacaoId)),
                  icon: _processando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline,
                          size: 18, color: Colors.white),
                  label: const Text('Concluir',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),

          if (_erro != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_erro!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.redDark)),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAcoesPendente() {
    return _buildCard(
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _processando ? null : _confirmarERecusar,
                icon: const Icon(Icons.close, size: 16, color: AppColors.red),
                label: const Text('Recusar',
                    style: TextStyle(fontSize: 13, color: AppColors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.redLight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _processando ? null : _confirmarEAceitar,
                icon: _processando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 16, color: Colors.white),
                label: const Text('Aceitar',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: AppColors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineItems(Solicitacao s) {
    if (s.historico.isNotEmpty) {
      return s.historico.asMap().entries.map((entry) {
        final i = entry.key;
        final h = entry.value;
        final isLast = i == s.historico.length - 1;
        final isCurrent = isLast && !s.status.isFinal;

        return TimelineItem(
          state: isCurrent ? TimelineDotState.current : TimelineDotState.done,
          label: StatusSolicitacaoX.fromString(h.statusNovo).label,
          sublabel: DateFormatter.dataHoraLocal(h.criadoEm).isNotEmpty
              ? DateFormatter.dataHoraLocal(h.criadoEm)
              : null,
          isLast: isLast && s.status.isFinal,
        );
      }).toList();
    }

    // Fallback visual quando histórico não vem no payload
    final statusOrdem = s.status == StatusSolicitacao.recusada
        ? [StatusSolicitacao.pendente, StatusSolicitacao.recusada]
        : [
            StatusSolicitacao.pendente,
            StatusSolicitacao.aceita,
            StatusSolicitacao.emExecucao,
            StatusSolicitacao.concluida,
          ];

    final currentIdx = statusOrdem.indexOf(s.status);

    return statusOrdem.asMap().entries.map((entry) {
      final i = entry.key;
      final st = statusOrdem[i];

      TimelineDotState dotState;
      if (i < currentIdx) {
        dotState = TimelineDotState.done;
      } else if (st == s.status) {
        dotState =
            s.status.isFinal ? TimelineDotState.done : TimelineDotState.current;
      } else {
        dotState = TimelineDotState.pending;
      }

      return TimelineItem(
        state: dotState,
        label: st.label,
        isLast: i == statusOrdem.length - 1,
      );
    }).toList();
  }

  Widget _buildCard({String? titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null) ...[
            Text(titulo,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 32),
            const SizedBox(height: 8),
            Text(_erro!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
