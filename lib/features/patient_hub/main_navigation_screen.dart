import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'meal_diary_screen.dart';
import '../food_database/food_search_screen.dart';
import '../social_lifestyle/non_scale_victories_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _abaAtualIndex = 0;

  // Lista com as telas que serão exibidas em cada aba do aplicativo
  final List<Widget> _telas = [
    const DashboardScreen(),     // Aba 0: Painel de Controle com Macros e Água
    const MealDiaryScreen(),     // Aba 1: Diário de Refeições por Turnos
    const FoodSearchScreen(),    // Aba 2: Base de Alimentos TACO/IBGE
    const NonScaleVictoriesScreen(), // Aba 3: Conquistas além da balança
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaAtualIndex,
        children: _telas,
      ),
      // 底部导航栏 - BOTTOM NAVIGATION BAR PREMIUM
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _abaAtualIndex,
          onTap: (index) {
            setState(() {
              _abaAtualIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primarySage,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, size: 26),
              label: 'Painel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              activeIcon: Icon(Icons.menu_book_rounded, size: 26),
              label: 'Diário',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, size: 26),
              label: 'Alimentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded),
              activeIcon: Icon(Icons.emoji_events_rounded, size: 26),
              label: 'Conquistas',
            ),
          ],
        ),
      ),
    );
  }
}
