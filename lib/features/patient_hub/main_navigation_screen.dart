import 'package:flutter/material.dart';
// 🚀 CORREÇÃO: Importações absolutas blindadas contra erros de pastas!
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/patient_hub/dashboard_screen.dart';
import 'package:nutri_life/features/patient_hub/diary_screen.dart'; 
import 'package:nutri_life/features/patient_hub/workouts_screen.dart';
import 'package:nutri_life/features/food_database/food_search_screen.dart';
import 'package:nutri_life/features/patient_hub/achievements_screen.dart'; 

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceAtual = 0;

  final List<Widget> _telas = [
    const DashboardScreen(),
    const DiaryScreen(),
    const WorkoutsScreen(), 
    const FoodSearchScreen(turno: 'Geral'),
    const AchievementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primarySage,
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Diário'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Alimentos'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Conquistas'),
        ],
      ),
    );
  }
}
