import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';
import '../services/websocket_service.dart';
import '../widgets/solicitacao_card.dart';
import 'detalhes_solicitacao_screen.dart';

class HistoricoTab extends StatefulWidget {
  const HistoricoTab({Key? key}) : super(key: key);

  @override
  State<HistoricoTab> createState() => HistoricoTabState();
}

class HistoricoTabState extends State<HistoricoTab> {
  List<Solicitacao> _todas = [];
  bool _carregando = true;
  String? _filtro;
  String? _erro;
  WsEvent? _ultimoEvento;

  final List<_Filtro> _filtros = const [
    _Filtro(label: 'Todas', valor: null),
    _Filtro(label: 'Ativas', valor: 'ativas'),
    _Filtro(label: 'Concluídas', valor: 'concluida'),
    _Filtro(label: 'Canceladas', valor: 'cancelada'),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void recarregar() => _carregar();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega quando chega um evento de mudança de status via WebSocket
    final evento = context.watch<WebSocketService>().ultimoEvento;
    if (evento != null && evento != _ultimoEvento) {
      _ultimoEvento = evento;
      const eventosDeReload = [
        'solicitacao.aceita',
        'solicitacao.recusada',
        'solicitacao.em_execucao',
        'solicitacao.concluida',
        'solicitacao.cancelada',
      ];
      if (eventosDeReload.contains(evento.evento)) {
        _carregar();
      }
    }
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final lista = await SolicitacaoService.listar();
      setState(() { _todas = lista; _carregando = false; });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  List<Solicitacao> get _filtradas {
    if (_filtro == null) return _todas;
    if (_filtro == 'ativas') return _todas.where((s) => s.status.isAtiva).toList();
    return _todas.where((s) => s.status.name == _filtro).toList();
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
          'Histórico',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: AppColors.bgPrimary,
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filtros.map((f) => _buildPill(f)).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _erro != null
                    ? RefreshIndicator(
                        onRefresh: _carregar,
                        color: AppColors.primary,
                        child: ListView(children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                              ]),
                            ),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                    onRefresh: _carregar,
                    color: AppColors.primary,
                    child: _filtradas.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'Nenhuma solicitação',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtradas.length,
                            itemBuilder: (_, i) => SolicitacaoCard(
                              solicitacao: _filtradas[i],
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetalhesSolicitacaoScreen(
                                      solicitacaoId: _filtradas[i].id,
                                    ),
                                  ),
                                );
                                _carregar();
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(_Filtro f) {
    final sel = _filtro == f.valor;
    return GestureDetector(
      onTap: () => setState(() => _filtro = f.valor),
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          f.label,
          style: TextStyle(
            fontSize: 13,
            color: sel ? Colors.white : AppColors.textSecondary,
            fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Filtro {
  final String label;
  final String? valor;
  const _Filtro({required this.label, this.valor});
}
