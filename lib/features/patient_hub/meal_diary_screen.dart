import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../food_database/food_search_screen.dart';

class MealDiaryScreen extends StatefulWidget {
  const MealDiaryScreen({Key? key}) : super(key: key);

  @override
  State<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends State<MealDiaryScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  late List<DateTime> _listaDeDias;
  int _diaSelecionadoIndex = 2; 

  @override
  void initState() {
    super.initState();
    _gerarLinhaDoTempoAvancada();
  }

  void _gerarLinhaDoTempoAvancada() {
    final hoje = DateTime.now();
    _listaDeDias = List.generate(5, (index) {
      return hoje.add(Duration(days: index - 2));
    });
  }

  String _formatarDataParaFirebase(DateTime data) {
    return "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
  }

  String _getNomeDiaSemana(int weekday) {
    const d = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return d[weekday];
  }

  @override
  Widget build(BuildContext context) {
    final DateTime dataSelecionada = _listaDeDias[_diaSelecionadoIndex];
    final String dataKey = _formatarDataParaFirebase(dataSelecionada);

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Diário Alimentar'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).snapshots(),
        builder: (context, userSnapshot) {
          Map<String, dynamic> planoAlimentar = {};
          
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final dadosUsuario = userSnapshot.data!.data() as Map<String, dynamic>;
            planoAlimentar = dadosUsuario['plano_alimentar'] ?? {};
          }

          final prescricaoCafe = planoAlimentar['cafe'] ?? "Nenhuma orientação cadastrada para este turno.";
          final prescricaoAlmoco = planoAlimentar['almoco'] ?? "Nenhuma orientação cadastrada para este turno.";
          final prescricaoLanche = planoAlimentar['lanche'] ?? "Nenhuma orientação cadastrada para este turno.";
          final prescricaoJantar = planoAlimentar['jantar'] ?? "Nenhuma orientação cadastrada para este turno.";

          return Column(
            children: [
              Container(
                color: AppColors.primarySage,
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _listaDeDias.length,
                    itemBuilder: (context, index) {
                      final dataItem = _listaDeDias[index];
                      bool isSelecionado = index == _diaSelecionadoIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _diaSelecionadoIndex = index),
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelecionado ? Colors.white : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getNomeDiaSemana(dataItem.weekday), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelecionado ? AppColors.primarySage : Colors.white70)),
                              const SizedBox(height: 4),
                              Text(dataItem.day.toString().padLeft(2, '0'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelecionado ? AppColors.textDark : Colors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(_userId)
                      .collection('diario')
                      .doc(dataKey)
                      .snapshots(),
                  builder: (context, diarySnapshot) {
                    List<dynamic> todosAlimentos = [];

                    if (diarySnapshot.hasData && diarySnapshot.data!.exists) {
                      final dadosDiario = diarySnapshot.data!.data() as Map<String, dynamic>;
                      todosAlimentos = dadosDiario['historico_alimentos'] ?? [];
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _ConstruirBlocoTurnoPremium(
                          titulo: 'Café da Manhã',
                          prescricaoTexto: prescricaoCafe,
                          alimentosDoTurno: todosAlimentos.where((a) => a['turno'] == 'Café da Manhã').toList(),
                          userId: _userId,
                          dataKey: dataKey,
                          kcalPadrao: 400, carbosPadrao: 45, proteinasPadrao: 25, gordurasPadrao: 12,
                          icone: Icons.wb_twilight_rounded, corIcone: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        _ConstruirBlocoTurnoPremium(
                          titulo: 'Almoço',
                          prescricaoTexto: prescricaoAlmoco,
                          alimentosDoTurno: todosAlimentos.where((a) => a['turno'] == 'Almoço').toList(),
                          userId: _userId,
                          dataKey: dataKey,
                          kcalPadrao: 700, carbosPadrao: 80, proteinasPadrao: 45, gordurasPadrao: 18,
                          icone: Icons.wb_sunny_rounded, corIcone: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _ConstruirBlocoTurnoPremium(
                          titulo: 'Lanche',
                          prescricaoTexto: prescricaoLanche,
                          alimentosDoTurno: todosAlimentos.where((a) => a['turno'] == 'Lanche').toList(),
                          userId: _userId,
                          dataKey: dataKey,
                          kcalPadrao: 300, carbosPadrao: 35, proteinasPadrao: 20, gordurasPadrao: 8,
                          icone: Icons.fastfood_rounded, corIcone: AppColors.accentPeach,
                        ),
                        const SizedBox(height: 16),
                        _ConstruirBlocoTurnoPremium(
                          titulo: 'Jantar',
                          prescricaoTexto: prescricaoJantar,
                          alimentosDoTurno: todosAlimentos.where((a) => a['turno'] == 'Jantar').toList(),
                          userId: _userId,
                          dataKey: dataKey,
                          kcalPadrao: 500, carbosPadrao: 40, proteinasPadrao: 40, gordurasPadrao: 15,
                          icone: Icons.nights_stay_rounded, corIcone: Colors.indigo,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConstruirBlocoTurnoPremium extends StatelessWidget {
  final String titulo;
  final String prescricaoTexto;
  final List<dynamic> alimentosDoTurno;
  final String userId;
  final String dataKey;
  final int kcalPadrao;
  final double carbosPadrao;
  final double proteinasPadrao;
  final double gordurasPadrao;
  final IconData icone;
  final Color corIcone;

  const _ConstruirBlocoTurnoPremium({
    required this.titulo,
    required this.prescricaoTexto,
    required this.alimentosDoTurno,
    required this.userId,
    required this.dataKey,
    required this.kcalPadrao,
    required this.carbosPadrao,
    required this.proteinasPadrao,
    required this.gordurasPadrao,
    required this.icone,
    required this.corIcone,
  });

  void _executarQuickLog(BuildContext context) async {
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataKey);

    await docRef.set({
      'calorias_consumidas': FieldValue.increment(kcalPadrao),
      'carbos_consumidos': FieldValue.increment(carbosPadrao),
      'proteinas_consumidos': FieldValue.increment(proteinasPadrao),
      'gorduras_consumidos': FieldValue.increment(gordurasPadrao),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': 'Refeição Prescrita Seguidinha',
          'turno': titulo,
          'quantidade': 1.0,
          'medida_escolhida': 'Plano Completo',
          'calorias': kcalPadrao,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$titulo computado com sucesso! 🎯'), backgroundColor: AppColors.primarySage),
      );
    }
  }

  // 🗑️ FUNÇÃO DE DELETAR (A BORRACHA)
  void _deletarAlimento(BuildContext context, Map<String, dynamic> item) async {
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataKey);

    // Subtrai as calorias e remove o item específico da lista na nuvem
    await docRef.update({
      'calorias_consumidas': FieldValue.increment(-(item['calorias'] as num).toInt()),
      'historico_alimentos': FieldValue.arrayRemove([item])
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['nome']} removido.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalKcalTurno = 0;
    for (var a in alimentosDoTurno) {
      totalKcalTurno += (a['calorias'] as num).toInt();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icone, color: corIcone, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
                Text('$totalKcalTurno kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primarySage)),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCreme.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primarySage.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.assignment_turned_in_rounded, size: 14, color: AppColors.primarySage),
                        SizedBox(width: 6),
                        Text('Meta Prescrita pela Nutri', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primarySage, letterSpacing: 0.3)),
                      ],
                    ),
                    if (alimentosDoTurno.isEmpty && prescricaoTexto.length > 50)
                      GestureDetector(
                        onTap: () => _executarQuickLog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primarySage, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Quick-Log ⚡', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  prescricaoTexto,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4, fontStyle: prescricaoTexto.contains('orientação') ? FontStyle.italic : FontStyle.normal),
                ),
              ],
            ),
          ),
          
          // LISTA DE ALIMENTOS COM SWIPE TO DELETE
          if (alimentosDoTurno.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alimentosDoTurno.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final item = alimentosDoTurno[index];
                
                // O widget Dismissible é o que cria a magia de "Deslizar para apagar"
                return Dismissible(
                  key: Key(item['timestamp'].toString()), // Identificador único na nuvem
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deletarAlimento(context, item);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['nome'] ?? 'Alimento', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 2),
                              Text("Qtd: ${item['quantidade']}x (${item['medida_escolhida'] ?? 'porção'})", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Text('${item['calorias']} kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                );
              },
            ),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FoodSearchScreen(turno: titulo)));
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.primarySage.withOpacity(0.04), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search, color: AppColors.primarySage, size: 16),
                  SizedBox(width: 6),
                  Text('Substituir ou Buscar Alimento', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
