import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/solicitacao.dart';
import '../models/veiculo.dart';
import '../services/solicitacao_service.dart';
import '../services/veiculo_service.dart';
import 'veiculos_tab.dart';

class NovaSolicitacaoScreen extends StatefulWidget {
  const NovaSolicitacaoScreen({Key? key}) : super(key: key);

  @override
  State<NovaSolicitacaoScreen> createState() => _NovaSolicitacaoScreenState();
}

class _NovaSolicitacaoScreenState extends State<NovaSolicitacaoScreen> {
  List<Veiculo> _veiculos = [];
  Veiculo? _veiculoSelecionado;
  TipoServico _tipoServico = TipoServico.simples;
  final _enderecoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _carregandoVeiculos = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  @override
  void dispose() {
    _enderecoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarVeiculos() async {
    try {
      final lista = await VeiculoService.listar();
      setState(() {
        _veiculos = lista;
        if (lista.isNotEmpty) _veiculoSelecionado = lista.first;
        _carregandoVeiculos = false;
      });
    } catch (e) {
      setState(() => _carregandoVeiculos = false);
    }
  }

  Future<void> _enviar() async {
    if (_veiculoSelecionado == null) {
      setState(() => _erro = 'Selecione um veículo');
      return;
    }
    if (_enderecoCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o endereço do lavador');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      await SolicitacaoService.criar(
        veiculoId: _veiculoSelecionado!.id,
        endereco: _enderecoCtrl.text.trim(),
        tipoServico: _tipoServico,
        observacoes: _obsCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
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
          'Nova solicitação',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Veículo
              _buildCard(
                titulo: 'Veículo',
                child: _carregandoVeiculos
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      )
                    : _veiculos.isEmpty
                        ? _buildSemVeiculos()
                        : Column(
                            children: [
                              DropdownButtonFormField<Veiculo>(
                                value: _veiculoSelecionado,
                                items: _veiculos
                                    .map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v.shortName,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _veiculoSelecionado = v),
                                decoration: _inputDecoration(),
                              ),
                            ],
                          ),
              ),

              const SizedBox(height: 8),

              // Tipo de serviço
              _buildCard(
                titulo: 'Tipo de serviço',
                child: Column(
                  children: [
                    Row(
                      children: TipoServico.values
                          .map((t) => _buildPillTipo(t))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tipoServico.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tipoServico.descricao,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Endereço e observações
              _buildCard(
                titulo: 'Localização',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Endereço do lavador'),
                    TextFormField(
                      controller: _enderecoCtrl,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                          hint: 'Ex: Av. Afonso Pena, 1500'),
                    ),
                    const SizedBox(height: 10),
                    _buildFieldLabel('Observações (opcional)'),
                    TextFormField(
                      controller: _obsCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                          hint: 'Ex: carro com barro nas rodas'),
                    ),
                  ],
                ),
              ),

              if (_erro != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.redDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed:
                      (_enviando || _veiculos.isEmpty) ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Solicitar lavagem',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String titulo, required Widget child}) {
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
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPillTipo(TipoServico t) {
    final sel = _tipoServico == t;
    return GestureDetector(
      onTap: () => setState(() => _tipoServico = t),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppColors.primaryBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          t.label,
          style: TextStyle(
            fontSize: 11,
            color: sel ? AppColors.primaryDark : AppColors.textSecondary,
            fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSemVeiculos() {
    return Column(
      children: [
        const Text(
          'Você ainda não tem veículos cadastrados.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VeiculosTab()),
            );
            _carregarVeiculos();
          },
          icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
          label: const Text(
            'Cadastrar veículo',
            style: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 12, color: AppColors.textTertiary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    );
  }
}
