import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/formatters/placa_formatter.dart';
import '../models/veiculo.dart';
import '../services/veiculo_service.dart';

class VeiculosTab extends StatefulWidget {
  const VeiculosTab({Key? key}) : super(key: key);

  @override
  State<VeiculosTab> createState() => _VeiculosTabState();
}

class _VeiculosTabState extends State<VeiculosTab> {
  List<Veiculo> _veiculos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await VeiculoService.listar();
      setState(() {
        _veiculos = lista;
        _carregando = false;
      });
    } catch (_) {
      setState(() => _carregando = false);
    }
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdicionarVeiculoSheet(
        onSalvo: (_) {
          Navigator.of(context).pop();
          _carregar();
        },
      ),
    );
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
          'Meus veículos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.add, color: AppColors.primary),
          ),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _carregar,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ..._veiculos.map((v) => _buildCard(v)),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(Veiculo v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car,
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.modelo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  v.cor != null ? '${v.cor} · ${v.placa}' : v.placa,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }

}

class _AdicionarVeiculoSheet extends StatefulWidget {
  final void Function(Veiculo) onSalvo;

  const _AdicionarVeiculoSheet({Key? key, required this.onSalvo})
      : super(key: key);

  @override
  State<_AdicionarVeiculoSheet> createState() =>
      _AdicionarVeiculoSheetState();
}

class _AdicionarVeiculoSheetState extends State<_AdicionarVeiculoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _modeloCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _modeloCtrl.dispose();
    _placaCtrl.dispose();
    _corCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final v = await VeiculoService.criar(
        placa: _placaCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        cor: _corCtrl.text.trim(),
      );
      widget.onSalvo(v);
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Adicionar veículo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                  label: 'Modelo', controller: _modeloCtrl, hint: 'Ex: Honda Civic'),
              _buildField(
                label: 'Placa',
                controller: _placaCtrl,
                hint: 'ABC-1234',
                inputFormatters: [PlacaInputFormatter()],
                keyboardType: TextInputType.text,
              ),
              _buildField(
                  label: 'Cor', controller: _corCtrl, hint: 'Ex: Prata', required: false),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(_erro!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.red)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = true,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null
                : null,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 12, color: AppColors.textTertiary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
