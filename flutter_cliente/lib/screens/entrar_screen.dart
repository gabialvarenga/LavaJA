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
  final _emailCtrl = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erro = 'Informe um e-mail válido');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    try {
      final response = await ApiClient.post('/usuarios/login', {'email': email});
      final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
      final usuario = Usuario.fromJson(data);

      if (usuario.tipo != 'cliente') {
        setState(() {
          _erro = 'Esta conta é de lavador. Use o app LavaJÁ Lavador.';
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
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.water_drop,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bem-vinda de volta!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use o e-mail cadastrado para entrar.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('E-mail',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: true,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'seu@email.com',
                              hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textTertiary),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  size: 18, color: AppColors.textTertiary),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
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
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            onSubmitted: (_) => _entrar(),
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
                                      fontSize: 12,
                                      color: AppColors.redDark)),
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
