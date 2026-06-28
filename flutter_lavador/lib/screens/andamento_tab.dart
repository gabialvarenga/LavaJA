import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';
import '../services/websocket_service.dart';
import '../widgets/solicitacao_card.dart';
import 'detalhes_solicitacao_screen.dart';

class AndamentoTab extends StatefulWidget {
  const AndamentoTab({Key? key}) : super(key: key);

  @override
  State<AndamentoTab> createState() => _AndamentoTabState();
}

class _AndamentoTabState extends State<AndamentoTab> {
  List<Solicitacao> _emAndamento = [];
  bool _carregando = true;
  String? _erro;
  WsEvent? _ultimoEvento;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wsEvent = context.watch<WebSocketService>().ultimoEvento;
    if (wsEvent != null && wsEvent != _ultimoEvento) {
      _ultimoEvento = wsEvent;
      const eventosDeReload = [
        'solicitacao.aceita',
        'solicitacao.em_execucao',
        'solicitacao.concluida',
        'solicitacao.recusada',
        'solicitacao.cancelada',
      ];
      if (eventosDeReload.contains(wsEvent.evento)) {
        _carregar();
      }
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // Carrega todas as solicitações e filtra as ativas do lavador logado
      final todas = await SolicitacaoService.listar();
      setState(() {
        _emAndamento = todas
            .where((s) =>
                s.status == StatusSolicitacao.aceita ||
                s.status == StatusSolicitacao.emExecucao)
            .toList();
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Em andamento',
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
          : _erro != null
              ? _buildErro()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: _emAndamento.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_outline,
                                    size: 36, color: AppColors.textTertiary),
                                SizedBox(height: 8),
                                Text(
                                  'Nenhum serviço em andamento',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _emAndamento.length,
                          itemBuilder: (_, i) => SolicitacaoCard(
                            solicitacao: _emAndamento[i],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetalhesSolicitacaoScreen(
                                    solicitacaoId: _emAndamento[i].id,
                                  ),
                                ),
                              );
                              _carregar();
                            },
                          ),
                        ),
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
            const Icon(Icons.cloud_off_outlined,
                size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(_erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
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
