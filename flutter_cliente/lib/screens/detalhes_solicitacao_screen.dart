import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
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
  bool _cancelando = false;
  String? _erro;
  WsEvent? _wsEventoAnterior;

  static const _ordemTimeline = [
    'pendente',
    'aceita',
    'emExecucao',
    'concluida',
  ];

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

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar solicitação'),
        content: const Text(
            'Tem certeza que deseja cancelar esta solicitação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, cancelar',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _cancelando = true);
    try {
      final atualizada =
          await SolicitacaoService.cancelar(widget.solicitacaoId);
      setState(() {
        _solicitacao = atualizada;
        _cancelando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _cancelando = false;
      });
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
            color: AppColors.textPrimary,
          ),
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
          // Cabeçalho
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
                const SizedBox(height: 4),
                Text(
                  s.veiculoDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.endereco,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Observações
          if (s.observacoes != null && s.observacoes!.isNotEmpty)
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Observações',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.observacoes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          if (s.observacoes != null && s.observacoes!.isNotEmpty)
            const SizedBox(height: 8),

          // Timeline
          _buildTimeline(s),

          const SizedBox(height: 8),

          // Ações
          if (s.status.podeSerCancelada)
            _buildCard(
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: _cancelando ? null : _cancelar,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.redLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _cancelando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppColors.red, strokeWidth: 2))
                      : const Text(
                          'Cancelar solicitação',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.red,
                          ),
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
              child: Text(
                _erro!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.redDark),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeline(Solicitacao s) {
    return _buildCard(
      titulo: 'Acompanhamento',
      child: Column(
        children: _buildTimelineItems(s),
      ),
    );
  }

  List<Widget> _buildTimelineItems(Solicitacao s) {
    // Se houver histórico real da API, usa ele
    if (s.historico.isNotEmpty) {
      return s.historico.asMap().entries.map((entry) {
        final i = entry.key;
        final h = entry.value;
        final isLast = i == s.historico.length - 1;
        final isCurrent = isLast &&
            s.status != StatusSolicitacao.concluida &&
            s.status != StatusSolicitacao.cancelada &&
            s.status != StatusSolicitacao.recusada;

        TimelineDotState dotState;
        if (isCurrent) {
          dotState = TimelineDotState.current;
        } else {
          dotState = TimelineDotState.done;
        }

        return TimelineItem(
          state: dotState,
          label: StatusSolicitacaoX.fromString(h.statusNovo).label,
          sublabel: h.criadoEm.length >= 16
              ? h.criadoEm.substring(11, 16)
              : null,
          isLast: isLast && _statusEhFinal(s.status),
        );
      }).toList();
    }

    // Fallback: timeline visual baseada no status atual
    final List<Widget> items = [];
    final statusOrdem = s.status == StatusSolicitacao.recusada
        ? ['pendente', 'recusada']
        : s.status == StatusSolicitacao.cancelada
            ? [
                ..._ordemTimeline
                    .takeWhile((x) => x != s.status.name)
                    .toList(),
                'cancelada'
              ]
            : _ordemTimeline;

    for (int i = 0; i < statusOrdem.length; i++) {
      final st = StatusSolicitacaoX.fromString(statusOrdem[i]);
      final currentIdx = _ordemTimeline.indexOf(s.status.name);
      final thisIdx = _ordemTimeline.indexOf(statusOrdem[i]);

      TimelineDotState dotState;
      if (thisIdx < currentIdx) {
        dotState = TimelineDotState.done;
      } else if (statusOrdem[i] == s.status.name) {
        dotState = _statusEhFinal(s.status)
            ? TimelineDotState.done
            : TimelineDotState.current;
      } else {
        dotState = TimelineDotState.pending;
      }

      items.add(TimelineItem(
        state: dotState,
        label: st.label,
        isLast: i == statusOrdem.length - 1,
      ));
    }
    return items;
  }

  bool _statusEhFinal(StatusSolicitacao s) =>
      s == StatusSolicitacao.concluida ||
      s == StatusSolicitacao.cancelada ||
      s == StatusSolicitacao.recusada;

  Widget _buildCard({String? titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null) ...[
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
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
            Text(
              _erro!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
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
