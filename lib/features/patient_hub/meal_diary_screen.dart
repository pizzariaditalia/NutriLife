import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/food_database/food_search_screen.dart';

class MealDiaryScreen extends StatefulWidget {
  const MealDiaryScreen({Key? key}) : super(key: key);

  @override
  State<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends State<MealDiaryScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  void _abrirBuscaAlimentos(String turno) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodSearchScreen(turno: turno)),
    );
  }

  void _deletarAlimento(Map<String, dynamic> alimento, String dataHoje) async {
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje);
    
    // Remove o alimento do array e subtrai as calorias consumidas do saldo diário
    await docRef.update({
      'historico_alimentos': FieldValue.arrayRemove([alimento]),
      'calorias_consumidas': FieldValue.increment(-(alimento['calorias'] ?? 0)),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alimento removido do diário. 🗑️')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = _getTodayDateKey();

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Cardápio e Diário', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 🚀 CONEXÃO 1: Lendo o perfil do usuário para pegar o plano alimentar prescrito na web
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).snapshots(),
        builder: (context, userSnap) {
          Map<String, dynamic> planoAlimentar = {};
          if (userSnap.hasData && userSnap.data!.exists) {
            final dadosUser = userSnap.data!.data() as Map<String, dynamic>?;
            planoAlimentar = dadosUser?['plano_alimentar'] ?? {};
          }

          return StreamBuilder<DocumentSnapshot>(
            // 🚀 CONEXÃO 2: Lendo o diário de hoje para ver o que o paciente já comeu
            stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
            builder: (context, diarioSnap) {
              List<dynamic> alimentosConsumidos = [];
              if (diarioSnap.hasData && diarioSnap.data!.exists) {
                final dadosDiario = diarioSnap.data!.data() as Map<String, dynamic>?;
                alimentosConsumidos = dadosDiario?['historico_alimentos'] ?? [];
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Plano Alimentar Prescrito 📋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text('Siga as orientações da sua nutricionista e registre o que consumiu.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 24),

                  _buildSecaoRefeicao('Café da Manhã', Icons.wb_twilight, planoAlimentar['cafe'], alimentosConsumidos, dataHoje),
                  _buildSecaoRefeicao('Almoço', Icons.wb_sunny, planoAlimentar['almoco'], alimentosConsumidos, dataHoje),
                  _buildSecaoRefeicao('Lanche', Icons.apple, planoAlimentar['lanche'], alimentosConsumidos, dataHoje),
                  _buildSecaoRefeicao('Jantar', Icons.nights_stay, planoAlimentar['jantar'], alimentosConsumidos, dataHoje),
                  
                  const SizedBox(height: 40),
                ],
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildSecaoRefeicao(String turno, IconData icone, String? prescricao, List<dynamic> todosConsumidos, String dataHoje) {
    // Filtra apenas os alimentos consumidos neste turno específico
    final consumidosNesteTurno = todosConsumidos.where((a) => a['turno'] == turno).toList();
    
    // Calcula o total de calorias já ingeridas neste turno
    int caloriasTurno = consumidosNesteTurno.fold(0, (soma, item) => soma + ((item['calorias'] ?? 0) as int));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO DO TURNO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primarySage.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icone, color: AppColors.primarySage, size: 24),
                    const SizedBox(width: 10),
                    Text(turno, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  ],
                ),
                Text('$caloriasTurno kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentPeach)),
              ],
            ),
          ),
          
          // PRESCRIÇÃO DA NUTRICIONISTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('PRESCRIÇÃO DA NUTRI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (prescricao != null && prescricao.trim().isNotEmpty) ? prescricao : 'Nenhuma orientação específica cadastrada.',
                  style: TextStyle(color: (prescricao != null && prescricao.trim().isNotEmpty) ? AppColors.textDark : Colors.grey.shade400, fontSize: 13, height: 1.4, fontStyle: (prescricao != null && prescricao.trim().isNotEmpty) ? FontStyle.normal : FontStyle.italic),
                ),
              ],
            ),
          ),

          // LISTA DE ALIMENTOS CONSUMIDOS
          if (consumidosNesteTurno.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: consumidosNesteTurno.map((alimento) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(alimento['nome'] ?? 'Alimento', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    subtitle: Text('${alimento['quantidade']}x ${alimento['medida_escolhida']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${alimento['calorias']} kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                          onPressed: () => _deletarAlimento(alimento, dataHoje),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // BOTÃO ADICIONAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _abrirBuscaAlimentos(turno),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primarySage),
                label: Text('Registrar consumo no $turno', style: const TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: AppColors.backgroundCreme, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          )
        ],
      ),
    );
  }
}
