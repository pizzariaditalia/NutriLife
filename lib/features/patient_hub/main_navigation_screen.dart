import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'interactive_menu_screen.dart';
import 'grocery_list_screen.dart';
import '../social_lifestyle/non_scale_victories_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceAtual = 0;

  // Lista com as telas que serão exibidas
  final List<Widget> _telas = [
    const DashboardScreen(),
    const InteractiveMenuScreen(),
    const GroceryListScreen(),
    const NonScaleVictoriesScreen(),
  ];

  void _aoTocarNaAba(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      // O corpo da tela muda dinamicamente conforme o índice selecionado
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceAtual,
          onTap: _aoTocarNaAba,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primarySage,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed, // Mantém os ícones fixos sem animações estranhas
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Painel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_rounded),
              label: 'Cardápio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket_rounded),
              label: 'Compras',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_rounded),
              label: 'Conquistas',
            ),
          ],
        ),
      ),
    );
  }
}
