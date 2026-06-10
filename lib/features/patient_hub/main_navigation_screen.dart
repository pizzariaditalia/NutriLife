import 'package:flutter/material.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/patient_hub/dashboard_screen.dart';
import 'package:nutri_life/features/patient_hub/meal_diary_screen.dart'; 
import 'package:nutri_life/features/ai_assistant/ai_assistant_screen.dart';
import 'package:nutri_life/features/patient_hub/workouts_screen.dart';
import 'package:nutri_life/features/food_database/food_search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceAtual = 0;

  final List<Widget> _telas = [
    const DashboardScreen(),
    const MealDiaryScreen(),
    const AiAssistantScreen(), // 🧠 Centro: IA embutida de forma estável
    const WorkoutsScreen(), 
    const FoodSearchScreen(turno: 'Geral'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primarySage,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Diário'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Assistente'), // ✨ Ícone do Gemini verde
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Alimentos'),
        ],
      ),
    );
  }
}
