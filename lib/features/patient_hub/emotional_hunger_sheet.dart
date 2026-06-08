import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../food_database/food_search_screen.dart'; // Importamos a tela de busca

class EmotionalHungerSheet extends StatefulWidget {
  const EmotionalHungerSheet({Key? key}) : super(key: key);

  @override
  State<EmotionalHungerSheet> createState() => _EmotionalHungerSheetState();
}

class _EmotionalHungerSheetState extends State<EmotionalHungerSheet> {
  int _selectedScore = 0;

  void _submitScore() {
    if (_selectedScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um nível de fome para continuar.'),
          backgroundColor: AppColors.accentPeach,
        ),
      );
      return;
    }

    // 1. Fecha o BottomSheet atual (Rastreador)
    Navigator.pop(context);
    
    // 2. Exibe o feedback visual de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nível $_selectedScore registrado! Vamos escolher sua refeição.'),
        backgroundColor: AppColors.secondaryMenta,
        duration: const Duration(seconds: 2),
      ),
    );

    // 3. Navega automaticamente para a tela de Busca de Alimentos
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCreme,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rastreador de Fome',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primarySage,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'De 1 a 5, quão faminto você está agora?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                int score = index + 1;
                bool isSelected = _selectedScore == score;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedScore = score;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentPeach : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.accentPeach : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.accentPeach.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _getHungerDescription(),
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySage,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Avançar para Refeição',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.backgroundCreme,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHungerDescription() {
    switch (_selectedScore) {
      case 1:
        return 'Estou sem fome, mas com vontade de comer (Ansiedade/Tédio).';
      case 2:
        return 'Fome muito leve, poderia esperar mais um pouco.';
      case 3:
        return 'Fome real, estômago começando a roncar.';
      case 4:
        return 'Muita fome, preciso me alimentar agora.';
      case 5:
        return 'Faminto ao extremo! Risco de comer muito rápido.';
      default:
        return 'Selecione um nível para continuar.';
    }
  }
}

