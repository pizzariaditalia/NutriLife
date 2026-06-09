import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Minhas Conquistas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 80, color: Colors.amber.shade400),
            const SizedBox(height: 16),
            Text('Conquistas em Breve 🏆', style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
