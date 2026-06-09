import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = _getTodayDateKey();

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Minhas Medalhas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
        builder: (context, diarioSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('galeria').doc('fotos_atuais').snapshots(),
            builder: (context, galeriaSnapshot) {
              
              // 🕹️ REGRAS DE GAMIFICAÇÃO
              bool jaComeuHoje = false;
              bool jaTreinouHoje = false;
              bool temFotosDaJornada = false;

              if (diarioSnapshot.hasData && diarioSnapshot.data!.exists) {
                final dadosDiario = diarioSnapshot.data!.data() as Map<String, dynamic>?;
                jaComeuHoje = (dadosDiario?['calorias_consumidas'] ?? 0) > 0;
                jaTreinouHoje = (dadosDiario?['calorias_queimadas'] ?? 0) > 0;
              }

              if (galeriaSnapshot.hasData && galeriaSnapshot.data!.exists) {
                final dadosGaleria = galeriaSnapshot.data!.data() as Map<String, dynamic>?;
                temFotosDaJornada = dadosGaleria != null && dadosGaleria.isNotEmpty;
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('Mural de Conquistas 🏆', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text('Bata suas metas diárias para colecionar insígnias de saúde.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 32),

                  _buildCardMedalha(
                    'Foco no Objetivo',
                    'Registrou o primeiro alimento no diário de refeições hoje.',
                    Icons.restaurant,
                    jaComeuHoje ? Colors.orange : Colors.grey.shade300,
                    jaComeuHoje,
                  ),
                  _buildCardMedalha(
                    'Estilo Strava',
                    'Registrou uma corrida, pedalada ou musculação na central de treinos.',
                    Icons.directions_run,
                    jaTreinouHoje ? AppColors.accentPeach : Colors.grey.shade300,
                    jaTreinouHoje,
                  ),
                  _buildCardMedalha(
                    'Foco Visual',
                    'Adicionou fotos de antes ou depois na galeria de evolução.',
                    Icons.camera_alt,
                    temFotosDaJornada ? AppColors.secondaryMenta : Colors.grey.shade300,
                    temFotosDaJornada,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCardMedalha(String titulo, String desc, IconData icone, Color corMedalha, bool desbloqueado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: corMedalha.withOpacity(0.15),
            child: Icon(icone, color: corMedalha, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    if (desbloqueado) const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
