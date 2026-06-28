import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../services/websocket_service.dart';
import 'home_tab.dart';
import 'historico_tab.dart';
import 'veiculos_tab.dart';
import 'perfil_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  final _historicoKey = GlobalKey<HistoricoTabState>();
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeTab(),
      HistoricoTab(key: _historicoKey),
      const VeiculosTab(),
      const PerfilTab(),
    ];
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      context.read<WebSocketService>().conectar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (i == 1) _historicoKey.currentState?.recarregar();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.bgPrimary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'veículos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'perfil',
          ),
        ],
      ),
    );
  }
}
