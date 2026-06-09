import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final TextEditingController _duracaoCtrl = TextEditingController();
  String _modalidadeSelecionada = 'Corrida';

  // 🏃 MET Simpificado (Fator de queima calórica por minuto)
  final Map<String, int> _fatorKcalPorMinuto = {
    'Corrida': 11,
    'Pedalada': 8,
    'Musculação': 5,
    'Caminhada': 4,
    'CrossFit': 12,
  };

  final Map<String, IconData> _iconesModalidades = {
    'Corrida': Icons.directions_run,
    'Pedalada': Icons.directions_bike,
    'Musculação': Icons.fitness_center,
    'Caminhada': Icons.directions_walk,
    'CrossFit': Icons.flash_on,
  };

  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  void _registrarTreino() async {
    if (_duracaoCtrl.text.isEmpty) return;
    int minutos = int.tryParse(_duracaoCtrl.text) ?? 0;
    if (minutos <= 0) return;

    int kcalPorMinuto = _fatorKcalPorMinuto[_modalidadeSelecionada] ?? 5;
    int totalQueimado = minutos * kcalPorMinuto;

    final dataHoje = _getTodayDateKey();
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje);

    await docRef.set({
      'calorias_queimadas': FieldValue.increment(totalQueimado),
      'historico_treinos': FieldValue.arrayUnion([
        {
          'modalidade': _modalidadeSelecionada,
          'duracao': minutos,
          'kcal_queimadas': totalQueimado,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    _duracaoCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 $_modalidadeSelecionada de ${minutos}min salva! -$totalQueimado kcal'), backgroundColor: AppColors.primarySage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = _getTodayDateKey();

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Central de Treinos', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Column(
        children: [
          // PAINEL DE ADICIONAR TREINO
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registrar Atividade Física ⚡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _modalidadeSelecionada,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: _fatorKcalPorMinuto.keys.map((String modalidade) {
                          return DropdownMenuItem<String>(value: modalidade, child: Text(modalidade));
                        }).toList(),
                        onChanged: (valor) => setState(() => _modalidadeSelecionada = valor ?? 'Corrida'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _duracaoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Minutos', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primarySage))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _registrarTreino,
                    child: const Text('Salvar no Histórico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),

          // LISTA DE TREINOS DO DIA (STREAM REAL)
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('Nenhum exercício registrado hoje.', style: TextStyle(color: Colors.grey.shade500)));
                }

                final dados = snapshot.data!.data() as Map<String, dynamic>?;
                final listaTreinos = dados?['historico_treinos'] as List<dynamic>? ?? [];

                if (listaTreinos.isEmpty) {
                  return Center(child: Text('Nenhum exercício registrado hoje.', style: TextStyle(color: Colors.grey.shade500)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: listaTreinos.length,
                  itemBuilder: (context, index) {
                    final treino = listaTreinos[index] as Map<String, dynamic>;
                    String modalidade = treino['modalidade'] ?? 'Exercício';
                    int duracao = treino['duracao'] ?? 0;
                    int kcal = treino['kcal_queimadas'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: AppColors.accentPeach.withOpacity(0.1), child: Icon(_iconesModalidades[modalidade] ?? Icons.flash_on, color: AppColors.accentPeach)),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(modalidade, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                                  Text('$duracao minutos ativos', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          Text('- $kcal kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orangeAccent)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
