import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Modelo de dados para as conquistas
class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final IconData icone;
  final int progressoAtual;
  final int meta;
  final bool desbloqueada;

  Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.progressoAtual,
    required this.meta,
    required this.desbloqueada,
  });

  double get porcentagem => progressoAtual / meta;
}

class NonScaleVictoriesScreen extends StatefulWidget {
  const NonScaleVictoriesScreen({Key? key}) : super(key: key);

  @override
  State<NonScaleVictoriesScreen> createState() => _NonScaleVictoriesScreenState();
}

class _NonScaleVictoriesScreenState extends State<NonScaleVictoriesScreen> {
  // Simulação do banco de dados de conquistas do paciente
  final List<Conquista> _conquistas = [
    Conquista(
      id: '1',
      titulo: 'Relógio Biológico',
      descricao: 'Dormiu 7+ horas por 5 dias seguidos.',
      icone: Icons.nights_stay_rounded,
      progressoAtual: 5,
      meta: 5,
      desbloqueada: true,
    ),
    Conquista(
      id: '2',
      titulo: 'Trânsito Livre',
      descricao: 'Melhorou o funcionamento intestinal.',
      icone: Icons.spa_rounded,
      progressoAtual: 1,
      meta: 1,
      desbloqueada: true,
    ),
    Conquista(
      id: '3',
      titulo: 'Constância de Ouro',
      descricao: 'Registrou todas as refeições por 7 dias.',
      icone: Icons.emoji_events_rounded,
      progressoAtual: 4,
      meta: 7,
      desbloqueada: false,
    ),
    Conquista(
      id: '4',
      titulo: 'Oásis de Hidratação',
      descricao: 'Atingiu a meta de água por 10 dias.',
      icone: Icons.water_drop_rounded,
      progressoAtual: 8,
      meta: 10,
      desbloqueada: false,
    ),
    Conquista(
      id: '5',
      titulo: 'Mestre Zen',
      descricao: 'Controlou a fome emocional no nível 5.',
      icone: Icons.self_improvement_rounded,
      progressoAtual: 0,
      meta: 3,
      desbloqueada: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Calculando o progresso geral
    int conquistasDesbloqueadas = _conquistas.where((c) => c.desbloqueada).length;
    int totalConquistas = _conquistas.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Além da Balança'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho de Gamificação
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primarySage,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 64,
                    color: AppColors.secondaryMenta,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Suas Vitórias Diárias',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você já desbloqueou $conquistasDesbloqueadas de $totalConquistas conquistas!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Texto Motivacional
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                'Lembre-se: O peso na balança é apenas um número. A verdadeira mudança acontece nos seus hábitos!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark,
                ),
              ),
            ),
            
            // Grid de Conquistas (Badges)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _conquistas.length,
                itemBuilder: (context, index) {
                  return _buildCardConquista(_conquistas[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardConquista(Conquista conquista) {
    return Container(
      decoration: BoxDecoration(
        color: conquista.desbloqueada ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: conquista.desbloqueada ? AppColors.secondaryMenta : Colors.grey.shade300,
          width: conquista.desbloqueada ? 2 : 1,
        ),
        boxShadow: conquista.desbloqueada
            ? [
                BoxShadow(
                  color: AppColors.secondaryMenta.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!conquista.desbloqueada)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: conquista.porcentagem,
                    backgroundColor: Colors.grey.shade300,
                    color: AppColors.accentPeach,
                    strokeWidth: 4,
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: conquista.desbloqueada
                      ? AppColors.secondaryMenta.withOpacity(0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  conquista.desbloqueada ? conquista.icone : Icons.lock_rounded,
                  size: 32,
                  color: conquista.desbloqueada ? AppColors.primarySage : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            conquista.titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: conquista.desbloqueada ? AppColors.textDark : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conquista.desbloqueada ? 'Desbloqueado!' : '${conquista.progressoAtual} / ${conquista.meta}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: conquista.desbloqueada ? AppColors.secondaryMenta : AppColors.accentPeach,
            ),
          ),
        ],
      ),
    );
  }
}
