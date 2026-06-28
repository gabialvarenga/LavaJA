import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/storage/local_storage.dart';
import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';
import '../services/websocket_service.dart';
import '../widgets/solicitacao_card.dart';
import 'detalhes_solicitacao_screen.dart';

class PendentesTab extends StatefulWidget {
  const PendentesTab({Key? key}) : super(key: key);

  @override
  State<PendentesTab> createState() => _PendentesTabState();
}

class _PendentesTabState extends State<PendentesTab> {
  List<Solicitacao> _pendentes = [];
  bool _carregando = true;
  String? _erro;
  String _nomeUsuario = '';
  WsEvent? _ultimoEvento;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wsEvent = context.watch<WebSocketService>().ultimoEvento;
    if (wsEvent != null && wsEvent != _ultimoEvento) {
      _ultimoEvento = wsEvent;
      if (wsEvent.evento == 'solicitacao.criada') {
        _carregar();
      }
    }
  }

  Future<void> _carregarDados() async {
    final nome = await LocalStorage.getUserName();
    setState(() => _nomeUsuario = nome ?? '');
    await _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await SolicitacaoService.listar(status: 'pendente');
      setState(() {
        _pendentes = lista;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  void _abrirDetalhes(Solicitacao s) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => DetalhesSolicitacaoScreen(solicitacaoId: s.id)),
    );
    _carregar();
  }

  String get _iniciais {
    final partes = _nomeUsuario.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'L';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTertiary,
      body: RefreshIndicator(
        onRefresh: _carregar,
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
                    if (_ultimoEvento?.evento == 'solicitacao.criada')
                      _buildBanner(),
                    const Text(
                      'Solicitações pendentes',
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
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (_erro != null)
                      _buildErro()
                    else if (_pendentes.isEmpty)
                      _buildVazio()
                    else
                      ..._pendentes
                          .map((s) => SolicitacaoCard(
                              solicitacao: s, onTap: () => _abrirDetalhes(s)))
                          .toList(),
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
                  const Text('Olá,',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(
                    _nomeUsuario.isNotEmpty
                        ? _nomeUsuario.split(' ').first
                        : 'Lavador',
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
                  _iniciais,
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
              _buildStat(_pendentes.length.toString(), 'pendentes'),
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

  Widget _buildBanner() {
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
          const Icon(Icons.notifications_active_outlined,
              size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nova solicitação recebida!',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _ultimoEvento = null),
            child: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
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
            Icon(Icons.inbox_outlined, size: 32, color: AppColors.textTertiary),
            SizedBox(height: 8),
            Text(
              'Nenhuma solicitação pendente',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            SizedBox(height: 4),
            Text(
              'Quando clientes enviarem pedidos, eles aparecerão aqui.',
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
            child: Text(_erro!,
                style: const TextStyle(fontSize: 12, color: AppColors.redDark)),
          ),
          TextButton(
            onPressed: _carregar,
            child: const Text('Tentar',
                style: TextStyle(fontSize: 11, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
