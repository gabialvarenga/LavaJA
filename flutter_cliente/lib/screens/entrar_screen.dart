import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/usuario.dart';
import 'main_screen.dart';

class EntrarScreen extends StatefulWidget {
  const EntrarScreen({Key? key}) : super(key: key);

  @override
  State<EntrarScreen> createState() => _EntrarScreenState();
}

class _EntrarScreenState extends State<EntrarScreen> {
  final _idCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _erro = 'Informe o ID do usuário');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    try {
      // Salva temporariamente para conseguir fazer a requisição autenticada
      await LocalStorage.saveUser(id: id, nome: '', email: '', tipo: 'cliente');

      final response = await ApiClient.get('/usuarios/$id');
      final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
      final usuario = Usuario.fromJson(data);

      if (usuario.tipo != 'cliente') {
        await LocalStorage.clear();
        setState(() {
          _erro = 'Este ID pertence a um lavador. Use o app LavaJÁ Lavador.';
          _carregando = false;
        });
        return;
      }

      await LocalStorage.saveUser(
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        tipo: usuario.tipo,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      await LocalStorage.clear();
      setState(() {
        _erro = 'ID não encontrado. Verifique o ID ou crie uma conta.';
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
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Entrar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_drop,
                        size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Bem-vinda de volta!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Informe o ID do seu usuário para continuar.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID do usuário',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _idCtrl,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                              hintStyle: const TextStyle(
                                  fontSize: 11, color: AppColors.textTertiary),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.border, width: 0.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.border, width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Encontre seu ID em: Perfil → ID do usuário',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
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
                              child: Text(_erro!,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.redDark)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _entrar,
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
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
