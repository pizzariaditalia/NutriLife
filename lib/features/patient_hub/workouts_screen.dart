import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meus Treinos', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Módulo Fitness em Construção 🚧', style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Aqui você registrará suas corridas e musculação.', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
