import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';

class BmiStatsScreen extends StatelessWidget {
  const BmiStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Estatísticas Corporais', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
          
          if (!userSnapshot.data!.exists) {
            return Center(child: Text('Perfil clínico não localizado.', style: TextStyle(color: Colors.grey.shade500)));
          }

          final dados = userSnapshot.data!.data() as Map<String, dynamic>;
          
          // 🚀 CONEXÃO DE FIOS: Puxa os dados cruzados com o Perfil e a Balança
          double altura = (dados['altura'] ?? 1.74).toDouble();
          double pesoInicial = (dados['peso_inicial'] ?? 87.4).toDouble();
          double pesoAtual = (dados['peso_atual'] ?? dados['peso_inicial'] ?? 87.4).toDouble();

          // Matemática Clínica do IMC
          double imc = pesoAtual / (altura * altura);
          
          // Classificação da OMS
          String status = 'Normal';
          Color corStatus = Colors.green;
          if (imc < 18.5) { status = 'Abaixo do Peso'; corStatus = Colors.orange; }
          else if (imc >= 18.5 && imc < 25) { status = 'Peso Saudável'; corStatus = AppColors.primarySage; }
          else if (imc >= 25 && imc < 30) { status = 'Sobrepeso'; corStatus = Colors.orangeAccent; }
          else { status = 'Obesidade'; corStatus = Colors.redAccent; }

          // Cálculo da faixa de peso ideal para esta altura
          double pesoMinIdeal = 18.5 * (altura * altura);
          double pesoMaxIdeal = 24.9 * (altura * altura);
          double evolucaoGeral = pesoAtual - pesoInicial;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // CARD MESTRE PREMIUM DO IMC
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                child: Column(
                  children: [
                    const Text('Seu Índice de Massa Corporal (IMC)', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(imc.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: corStatus.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text(status, style: TextStyle(color: corStatus, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD METRICAS DETALHADAS
              Row(
                children: [
                  Expanded(child: _miniMetrica('Altura Cadastrada', '${altura.toStringAsFixed(2)} m', Icons.height, Colors.teal)),
                  const SizedBox(width: 16),
                  Expanded(child: _miniMetrica('Evolução do Peso', '${evolucaoGeral >= 0 ? '+' : ''}${evolucaoGeral.toStringAsFixed(1)} kg', Icons.analytics, evolucaoGeral <= 0 ? AppColors.primarySage : Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 20),

              // CARD DE RECOMENDAÇÃO DE PESO IDEAL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1E2126), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety, color: AppColors.secondaryMenta, size: 24),
                        SizedBox(width: 10),
                        Text('Faixa de Peso Ideal Recomendada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Para sua altura de ${altura.toStringAsFixed(2)}m, a meta ideal de peso pela OMS é estar entre ${pesoMinIdeal.toStringAsFixed(1)}kg e ${pesoMaxIdeal.toStringAsFixed(1)}kg.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Histórico Cronológico de Pesagens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 12),

              // LISTA DO HISTÓRICO REAL DE PESAGENS DA BALANÇA
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('historico_peso').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, historicSnap) {
                  if (!historicSnap.hasData || historicSnap.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text('Nenhuma pesagem antiga encontrada.', style: TextStyle(color: Colors.grey.shade500)),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historicSnap.data!.docs.length,
                    itemBuilder: (context, i) {
                      final logPeso = historicSnap.data!.docs[i].data() as Map<String, dynamic>;
                      double pesoValor = (logPeso['peso'] ?? 0.0).toDouble();
                      String dataLog = logPeso['data'] ?? '--/--/----';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: Colors.grey.shade50, child: const Icon(Icons.scale, color: Colors.grey, size: 20)),
                                const SizedBox(width: 16),
                                Text(dataLog, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark)),
                              ],
                            ),
                            Text('${pesoValor.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }

  Widget _miniMetrica(String tit, String val, IconData ico, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ico, color: cor, size: 24),
          const SizedBox(height: 10),
          Text(tit, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
