import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'emotional_hunger_sheet.dart'; // Importando a folha de fome emocional

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int metaCalorica = 2000;
  int caloriasConsumidas = 1450;
  int caloriasExercicio = 300;
  int aguaConsumidaMl = 1200;
  final int metaAguaMl = 2500;

  int get caloriasRestantes => metaCalorica - caloriasConsumidas + caloriasExercicio;

  void _adicionarAgua() {
    setState(() {
      if (aguaConsumidaMl < metaAguaMl) {
        aguaConsumidaMl += 250;
      }
    });
    
    if (aguaConsumidaMl >= metaAguaMl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parabéns! Meta de hidratação alcançada! 💧'),
          backgroundColor: AppColors.secondaryMenta,
        ),
      );
    }
  }

  // Abre a janela inferior da Fome Emocional
  void _abrirRastreadorFome() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmotionalHungerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Painel'),
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContadorInteligente(),
              const SizedBox(height: 24),
              _buildCardHidratacao(),
              const SizedBox(height: 24),
              _buildAcoesRapidas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContadorInteligente() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Calorias Restantes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$caloriasRestantes',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primarySage,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniEstatistica('Meta', metaCalorica.toString(), Icons.flag),
              _buildMiniEstatistica('Consumo', caloriasConsumidas.toString(), Icons.restaurant),
              _buildMiniEstatistica('Treino', caloriasExercicio.toString(), Icons.fitness_center),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniEstatistica(String titulo, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, size: 20, color: AppColors.secondaryMenta),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        Text(
          titulo,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCardHidratacao() {
    double progressoAgua = aguaConsumidaMl / metaAguaMl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryMenta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryMenta.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hidratação Diária',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySage,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$aguaConsumidaMl / $metaAguaMl ml',
                  style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressoAgua > 1.0 ? 1.0 : progressoAgua,
                  backgroundColor: Colors.white,
                  color: AppColors.secondaryMenta,
                  minHeight: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _adicionarAgua,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySage,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.water_drop, color: AppColors.backgroundCreme),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _abrirRastreadorFome, // Aciona o método de abrir o BottomSheet
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primarySage),
            label: const Text(
              'Refeição',
              style: TextStyle(color: AppColors.primarySage),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Próxima funcionalidade: Scanner de Código de Barras
            },
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primarySage),
            label: const Text(
              'Scanner',
              style: TextStyle(color: AppColors.primarySage),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

