import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Modelo para as opções de troca
class OpcaoTroca {
  final String nome;
  final String medidaCalculada;
  final int caloriasExatas;

  OpcaoTroca({
    required this.nome,
    required this.medidaCalculada,
    required this.caloriasExatas,
  });
}

class SmartSwapsScreen extends StatefulWidget {
  const SmartSwapsScreen({Key? key}) : super(key: key);

  @override
  State<SmartSwapsScreen> createState() => _SmartSwapsScreenState();
}

class _SmartSwapsScreenState extends State<SmartSwapsScreen> {
  // Alimento original que o usuário quer substituir
  final String alimentoOriginal = 'Pão Francês';
  final String porcaoOriginal = '1 unidade (50g)';
  final int caloriasOriginais = 150;

  // Lista de substitutos equivalentes já calculados para bater ~150 kcal
  final List<OpcaoTroca> opcoesDeTroca = [
    OpcaoTroca(
      nome: 'Goma de Tapioca',
      medidaCalculada: '3 colheres de sopa cheias (60g)',
      caloriasExatas: 150,
    ),
    OpcaoTroca(
      nome: 'Cuscuz de Milho (Flocão)',
      medidaCalculada: '4 colheres de sopa cheias (130g pronto)',
      caloriasExatas: 148,
    ),
    OpcaoTroca(
      nome: 'Pão de Forma Integral',
      medidaCalculada: '2 fatias (50g)',
      caloriasExatas: 145,
    ),
    OpcaoTroca(
      nome: 'Crepioca (Ovo + Tapioca)',
      medidaCalculada: '1 ovo + 1.5 colher de tapioca',
      caloriasExatas: 155,
    ),
    OpcaoTroca(
      nome: 'Batata Doce Cozida',
      medidaCalculada: '1 fatia média/grande (150g)',
      caloriasExatas: 145,
    ),
  ];

  void _confirmarTroca(OpcaoTroca opcao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${opcao.nome} substituído com sucesso no cardápio!'),
        backgroundColor: AppColors.secondaryMenta,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Simula a volta para o cardápio após a troca
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Troca Inteligente'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho mostrando o alimento original
            Container(
              width: double.infinity,
              color: AppColors.primarySage,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Você quer substituir:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alimentoOriginal,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySage,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      porcaoOriginal,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Divider(height: 24, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department, color: AppColors.accentPeach, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$caloriasOriginais kcal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPeach,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de Opções Equivalentes
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opções Equivalentes (Carboidratos)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: opcoesDeTroca.length,
                        itemBuilder: (context, index) {
                          final opcao = opcoesDeTroca[index];
                          return _buildCardTroca(opcao);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTroca(OpcaoTroca opcao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _confirmarTroca(opcao),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.secondaryMenta, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opcao.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opcao.medidaCalculada,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '~${opcao.caloriasExatas}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primarySage,
                    ),
                  ),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primarySage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
