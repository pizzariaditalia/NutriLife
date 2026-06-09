import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class BmiStatsScreen extends StatelessWidget {
  const BmiStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Estatísticas Corporais', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('usuarios').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
          }

          final dados = snapshot.data!.data() as Map<String, dynamic>?;
          if (dados == null || dados['altura'] == null || dados['peso_inicial'] == null) {
            return const Center(child: Text('Preencha seu peso e altura no Perfil primeiro.'));
          }

          // Converte com segurança
          double altura = double.tryParse(dados['altura'].toString()) ?? 1.70;
          double peso = double.tryParse(dados['peso_inicial'].toString()) ?? 70.0;
          
          if (altura > 3.0) altura = altura / 100; // Caso o usuário digite 174 em vez de 1.74

          // Cálculo do IMC
          double imc = peso / (altura * altura);
          
          // Classificação
          String classificacao = '';
          Color corStatus = Colors.grey;
          double pesoIdealMax = 24.9 * (altura * altura);
          double diferenca = peso - pesoIdealMax;

          if (imc < 18.5) { classificacao = 'Abaixo do Peso'; corStatus = Colors.blue; }
          else if (imc >= 18.5 && imc < 24.9) { classificacao = 'Peso Normal (Saudável)'; corStatus = AppColors.secondaryMenta; }
          else if (imc >= 25 && imc < 29.9) { classificacao = 'Sobrepeso'; corStatus = AppColors.accentPeach; }
          else { classificacao = 'Obesidade'; corStatus = Colors.redAccent; }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Seu Índice de Massa Corporal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 32),
                
                // Medidor Visual Simplificado
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200, height: 200,
                      child: CircularProgressIndicator(
                        value: (imc / 40).clamp(0.0, 1.0), // Normaliza o IMC em uma escala até 40
                        strokeWidth: 20,
                        backgroundColor: Colors.grey.shade200,
                        color: corStatus,
                      ),
                    ),
                    Column(
                      children: [
                        Text(imc.toStringAsFixed(1), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: corStatus)),
                        Text('IMC', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      Text(classificacao, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: corStatus)),
                      const SizedBox(height: 12),
                      Text(
                        diferenca > 0 
                          ? 'Faltam ${diferenca.toStringAsFixed(1)} kg para você atingir a zona de peso normal para a sua altura (${altura.toStringAsFixed(2)}m).'
                          : 'Você está dentro ou abaixo da meta de peso normal!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
