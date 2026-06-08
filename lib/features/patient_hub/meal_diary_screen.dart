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
  int _diaSelecionadoIndex = 2; // Começa fixado no "Hoje" (meio da lista)

  @override
  void initState() {
    super.initState();
    _gerarLinhaDoTempoAvançada();
  }

  // 📅 Gera uma linha do tempo real com: 2 dias atrás, Hoje, e 2 dias para frente
  void _gerarLinhaDoTempoAvançada() {
    final hoje = DateTime.now();
    _listaDeDias = List.generate(5, (index) {
      return hoje.add(Duration(days: index - 2));
    });
  }

  // Converte o objeto DateTime do calendário para a chave de texto "AAAA-MM-DD" usada no Firebase
  String _formatarDataParaFirebase(DateTime data) {
    return "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
  }

  String _getNomeDiaSemana(int weekday) {
    switch (weekday) {
      case 1: return 'SEG';
      case 2: return 'TER';
      case 3: return 'QUA';
      case 4: return 'QUI';
      case 5: return 'SEX';
      case 6: return 'SÁB';
      default: return 'DOM';
    }
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
      body: Column(
        children: [
          // 1. SELETOR DE DATA DINÂMICO PREMIUM
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
                    onTap: () {
                      setState(() {
                        _diaSelecionadoIndex = index;
                      });
                    },
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
                          Text(
                            _getNomeDiaSemana(dataItem.weekday),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelecionado ? AppColors.primarySage : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dataItem.day.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelecionado ? AppColors.textDark : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. MONITOR REATIVO DO DIÁRIO
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(_userId)
                  .collection('diario')
                  .doc(dataKey)
                  .snapshots(),
              builder: (context, snapshot) {
                List<dynamic> todosAlimentos = [];

                if (snapshot.hasData && snapshot.data!.exists) {
                  final dados = snapshot.data!.data() as Map<String, dynamic>;
                  todosAlimentos = dados['historico_alimentos'] ?? [];
                }

                // Separa os alimentos em caixas de turnos específicas filtrando o histórico da nuvem
                final cafeDaManha = todosAlimentos.where((a) => a['turno'] == 'Café da Manhã').toList();
                final almoco = todosAlimentos.where((a) => a['turno'] == 'Almoço').toList();
                final lanche = todosAlimentos.where((a) => a['turno'] == 'Lanche').toList();
                final jantar = todosAlimentos.where((a) => a['turno'] == 'Jantar').toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ConstruirBlocoTurno(
                      titulo: 'Café da Manhã',
                      subtitulo: 'Meta sugerida: 400 - 500 kcal',
                      icone: Icons.wb_twilight_rounded,
                      corIcone: Colors.amber,
                      alimentosDoTurno: cafeDaManha,
                    ),
                    const SizedBox(height: 16),
                    _ConstruirBlocoTurno(
                      titulo: 'Almoço',
                      subtitulo: 'Meta sugerida: 600 - 800 kcal',
                      icone: Icons.wb_sunny_rounded,
                      corIcone: Colors.orange,
                      alimentosDoTurno: almoco,
                    ),
                    const SizedBox(height: 16),
                    _ConstruirBlocoTurno(
                      titulo: 'Lanche',
                      subtitulo: 'Meta sugerida: 200 - 300 kcal',
                      icone: Icons.fastfood_rounded,
                      corIcone: AppColors.accentPeach,
                      alimentosDoTurno: lanche,
                    ),
                    const SizedBox(height: 16),
                    _ConstruirBlocoTurno(
                      titulo: 'Jantar',
                      subtitulo: 'Meta sugerida: 400 - 600 kcal',
                      icone: Icons.nights_stay_rounded,
                      corIcone: Colors.indigo,
                      alimentosDoTurno: jantar,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstruirBlocoTurno extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color corIcone;
  final List<dynamic> alimentosDoTurno;

  const _ConstruirBlocoTurno({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.corIcone,
    required this.alimentosDoTurno,
  });

  @override
  Widget build(BuildContext context) {
    // Soma as calorias consumidas apenas neste turno específico
    int totalKcalTurno = 0;
    for (var alimento in alimentosDoTurno) {
      totalKcalTurno += (alimento['calorias'] as num).toInt();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Text(
                  '$totalKcalTurno kcal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primarySage),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Renderiza dinamicamente a lista de alimentos inseridos neste turno
          if (alimentosDoTurno.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alimentosDoTurno.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final item = alimentosDoTurno[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nome'] ?? 'Alimento',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text("Qtd: ${item['quantidade']}x (${item['medida_escolhida'] ?? 'porção'})",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Text('${item['calorias']} kcal',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                    ],
                  ),
                );
              },
            ),

          // Direciona o paciente para a tela de pesquisa passando o Turno correto por parâmetro
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodSearchScreen(turno: titulo),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySage.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: AppColors.primarySage, size: 18),
                  const SizedBox(width: 6),
                  Text('Adicionar Alimento', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
