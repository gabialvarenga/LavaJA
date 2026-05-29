import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/storage/local_storage.dart';
import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';
import '../services/websocket_service.dart';
import '../widgets/solicitacao_card.dart';
import 'nova_solicitacao_screen.dart';
import 'detalhes_solicitacao_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Solicitacao> _solicitacoes = [];
  bool _carregando = true;
  String? _erro;
  String _nomeUsuario = '';
  WsEvent? _notificacaoAtual;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reage a novos eventos do WebSocket
    final wsEvent = context.watch<WebSocketService>().ultimoEvento;
    if (wsEvent != null && wsEvent != _notificacaoAtual) {
      _notificacaoAtual = wsEvent;
      // Atualiza a lista quando chega evento relevante
      final eventosDeReload = [
        'solicitacao.aceita',
        'solicitacao.recusada',
        'solicitacao.em_execucao',
        'solicitacao.concluida',
        'solicitacao.cancelada',
      ];
      if (eventosDeReload.contains(wsEvent.evento)) {
        _carregarSolicitacoes();
      }
    }
  }

  Future<void> _carregarDados() async {
    final nome = await LocalStorage.getUserName();
    setState(() => _nomeUsuario = nome ?? '');
    await _carregarSolicitacoes();
  }

  Future<void> _carregarSolicitacoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await SolicitacaoService.listar();
      setState(() {
        _solicitacoes = lista;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  int get _ativas =>
      _solicitacoes.where((s) => s.status.isAtiva).length;

  void _abrirNovaSolicitacao() async {
    final criada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NovaSolicitacaoScreen()),
    );
    if (criada == true) _carregarSolicitacoes();
  }

  void _abrirDetalhes(Solicitacao s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => DetalhesSolicitacaoScreen(solicitacaoId: s.id)),
    );
    _carregarSolicitacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTertiary,
      body: RefreshIndicator(
        onRefresh: _carregarSolicitacoes,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_notificacaoAtual != null) _buildNotificacao(),
                    const SizedBox(height: 4),
                    const Text(
                      'Minhas solicitações',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_carregando)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      )
                    else if (_erro != null)
                      _buildErro()
                    else if (_solicitacoes.isEmpty)
                      _buildVazio()
                    else
                      ..._solicitacoes
                          .take(10)
                          .map((s) => SolicitacaoCard(
                              solicitacao: s,
                              onTap: () => _abrirDetalhes(s)))
                          .toList(),
                    const SizedBox(height: 8),
                    _buildBotaoNova(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá,',
                    style:
                        TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    _nomeUsuario.isNotEmpty
                        ? _nomeUsuario.split(' ').first
                        : 'LavaJÁ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Text(
                  _nomeUsuario.isNotEmpty
                      ? _nomeUsuario[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat(_ativas.toString(), 'ativas'),
              const SizedBox(width: 8),
              _buildStat(_solicitacoes.length.toString(), 'total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacao() {
    final evento = _notificacaoAtual!.evento;
    String mensagem = '';
    switch (evento) {
      case 'solicitacao.aceita':
        mensagem = 'Sua solicitação foi aceita por um lavador';
        break;
      case 'solicitacao.recusada':
        mensagem = 'Sua solicitação foi recusada';
        break;
      case 'solicitacao.em_execucao':
        mensagem = 'Lavagem iniciada!';
        break;
      case 'solicitacao.concluida':
        mensagem = 'Lavagem concluída!';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _notificacaoAtual = null),
            child: const Icon(Icons.close,
                size: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.water_drop,
                size: 32, color: AppColors.textTertiary),
            SizedBox(height: 8),
            Text(
              'Nenhuma solicitação ainda',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            SizedBox(height: 4),
            Text(
              'Crie sua primeira solicitação de lavagem!',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _erro!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.redDark),
            ),
          ),
          TextButton(
            onPressed: _carregarSolicitacoes,
            child: const Text('Tentar',
                style: TextStyle(fontSize: 11, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoNova() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: _abrirNovaSolicitacao,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: const Text(
          'Nova solicitação',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          primary: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
