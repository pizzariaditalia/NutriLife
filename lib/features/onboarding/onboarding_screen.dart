import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../patient_hub/main_navigation_screen.dart'; // Importação atualizada!

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedProfile;

  void _selectProfile(String profile) {
    setState(() {
      _selectedProfile = profile;
    });
  }

  void _saveProfile() {
    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um objetivo para continuar.'),
          backgroundColor: AppColors.accentPeach,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil "$_selectedProfile" definido com sucesso!'),
        backgroundColor: AppColors.secondaryMenta,
        duration: const Duration(seconds: 1),
      ),
    );

    // Agora navegamos para a Tela de Navegação Principal que contém todas as abas
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Seu Objetivo'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Qual é o seu foco principal?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primarySage,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vamos adaptar sua experiência baseada na sua escolha.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildProfileOption(
                title: 'Emagrecimento Definitivo',
                description: 'Foco em déficit calórico e volume nutricional.',
                icon: Icons.monitor_weight_outlined,
              ),
              const SizedBox(height: 16),
              
              _buildProfileOption(
                title: 'Saúde & Longevidade',
                description: 'Equilíbrio, micronutrientes e disposição.',
                icon: Icons.favorite_border_rounded,
              ),
              const SizedBox(height: 16),
              
              _buildProfileOption(
                title: 'Gestante ou Tentante',
                description: 'Acompanhamento focado na gestação saudável.',
                icon: Icons.child_care_rounded,
              ),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySage,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.backgroundCreme,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required String description,
    required IconData icon,
  }) {
    final bool isSelected = _selectedProfile == title;

    return GestureDetector(
      onTap: () => _selectProfile(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryMenta.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.secondaryMenta : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primarySage : Colors.grey.shade500,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primarySage : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.secondaryMenta,
              ),
          ],
        ),
      ),
    );
  }
}

