import 'package:flutter/material.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/patient_hub/dashboard_screen.dart';
import 'package:nutri_life/features/patient_hub/meal_diary_screen.dart'; 
import 'package:nutri_life/features/patient_hub/workouts_screen.dart';
import 'package:nutri_life/features/food_database/food_search_screen.dart';
// 🚀 NOVO IMPORT: Conecta a tela da IA
import 'package:nutri_life/features/ai_assistant/ai_assistant_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceAtual = 0;

  // 📝 Lista de Telas do Aplicativo
  final List<Widget> _telas = [
    const DashboardScreen(),
    const MealDiaryScreen(),
    const AiAssistantScreen(), // 🧠 Centro: Assistente Nutri (IA)
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
      // 🚀 O BOTÃO FLUTUANTE DA IA (ESTILO MERCADO PAGO)
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _indiceAtual = 2),
        backgroundColor: AppColors.primarySage,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28), // Ícone de Faísca/Brilho do Gemini
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // 🚀 BARRA DE NAVEGAÇÃO PREMIUM COM RECORTE
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // LADO ESQUERDO DO BOTÃO CENTRAL
              _buildBarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Painel'),
              _buildBarItem(1, Icons.menu_book_outlined, Icons.menu_book, 'Diário'),
              
              const SizedBox(width: 40), // Espaço cirúrgico para o botão da IA respirar no centro
              
              // LADO DIREITO DO BOTÃO CENTRAL
              _buildBarItem(3, Icons.fitness_center_outlined, Icons.fitness_center, 'Treinos'),
              _buildBarItem(4, Icons.search, Icons.search, 'Alimentos'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem(int index, IconData iconeInativo, IconData iconeAtivo, String label) {
    bool ativo = _indiceAtual == index;
    return GestureDetector(
      onTap: () => setState(() => _indiceAtual = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            ativo ? iconeAtivo : iconeInativo,
            color: ativo ? AppColors.primarySage : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
              color: ativo ? AppColors.primarySage : Colors.grey.shade400,
            ),
          )
        ],
      ),
    );
  }
}
