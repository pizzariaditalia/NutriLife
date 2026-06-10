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
        title: const Text('Minhas Medalhas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
        builder: (context, diarioSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('galeria').doc('fotos_atuais').snapshots(),
            builder: (context, galeriaSnapshot) {
              
              int consumido = 0;
              int agua = 0;
              bool jaComeuHoje = false;
              bool jaTreinouHoje = false;
              bool temFotosDaJornada = false;
              bool monstroDasProteinas = false;

              if (diarioSnapshot.hasData && diarioSnapshot.data!.exists) {
                final dadosDiario = diarioSnapshot.data!.data() as Map<String, dynamic>?;
                consumido = dadosDiario?['calorias_consumidas'] ?? 0;
                agua = dadosDiario?['agua_consumida'] ?? 0;
                jaComeuHoje = consumido > 0;
                jaTreinouHoje = (dadosDiario?['calorias_queimadas'] ?? 0) > 0;
                monstroDasProteinas = (dadosDiario?['proteinas_consumidos'] ?? 0) >= 100;
              }

              if (galeriaSnapshot.hasData && galeriaSnapshot.data!.exists) {
                final dadosGaleria = galeriaSnapshot.data!.data() as Map<String, dynamic>?;
                temFotosDaJornada = dadosGaleria != null && dadosGaleria.isNotEmpty;
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('Mural de Conquistas 🏆', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text('Evolua sua rotina saudável diariamente para desbloquear todas as 12 insígnias.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 32),

                  // 🏅 AS 12 MEDALHAS DO APLICATIVO
                  _buildCardMedalha('1. Foco no Objetivo', 'Registrou o primeiro alimento no diário de refeições.', Icons.restaurant, jaComeuHoje ? Colors.orange : Colors.grey.shade300, jaComeuHoje),
                  _buildCardMedalha('2. Estilo Strava', 'Registrou uma corrida, pedalada ou musculação na central.', Icons.directions_run, jaTreinouHoje ? AppColors.accentPeach : Colors.grey.shade300, jaTreinouHoje),
                  _buildCardMedalha('3. Foco Visual', 'Adicionou fotos de antes ou depois na galeria de evolução.', Icons.camera_alt, temFotosDaJornada ? AppColors.secondaryMenta : Colors.grey.shade300, temFotosDaJornada),
                  _buildCardMedalha('4. Monstro do Whey', 'Bateu mais de 100g de proteína pura em um único dia.', Icons.fitness_center, monstroDasProteinas ? Colors.blue : Colors.grey.shade300, monstroDasProteinas),
                  _buildCardMedalha('5. Oásis da Hidratação', 'Bebeu 2 Litros (2000ml) de água hoje pelo rastreador.', Icons.water_drop, agua >= 2000 ? Colors.cyan : Colors.grey.shade300, agua >= 2000),
                  _buildCardMedalha('6. Déficit Impecável', 'Manteve a risca as calorias abaixo da meta até o fim do dia.', Icons.trending_down, (consumido > 0 && consumido < 2000) ? Colors.teal : Colors.grey.shade300, (consumido > 0 && consumido < 2000)),
                  _buildCardMedalha('7. Controle de Peso', 'Encarou a balança e atualizou seu peso no painel.', Icons.scale, Colors.grey.shade300, false), // Fica cinza até a verificação futura
                  _buildCardMedalha('8. Mestre do Jejum', 'Concluiu o seu primeiro ciclo completo de Jejum Intermitente.', Icons.hourglass_top, Colors.grey.shade300, false),
                  _buildCardMedalha('9. Paciente Dedicado', 'Enviou sua primeira dúvida no chat em tempo real para a IA.', Icons.quickreply, Colors.grey.shade300, false),
                  _buildCardMedalha('10. Fidelidade Suprema', 'Abriu e atualizou o aplicativo por 7 dias seguidos.', Icons.workspace_premium, Colors.grey.shade300, false),
                  _buildCardMedalha('11. Chef Saudável', 'Criou e registrou uma receita customizada exclusiva própria.', Icons.blender, Colors.grey.shade300, false),
                  _buildCardMedalha('12. Rei da Constância', 'Registrou refeições e treinos 30 dias ininterruptos.', Icons.local_fire_department, Colors.grey.shade300, false),
                  
                  const SizedBox(height: 40),
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
        border: Border.all(color: desbloqueado ? corMedalha.withOpacity(0.5) : Colors.grey.shade200, width: desbloqueado ? 2 : 1),
        boxShadow: desbloqueado ? [BoxShadow(color: corMedalha.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30, 
            backgroundColor: corMedalha.withOpacity(0.15), 
            child: Icon(icone, color: corMedalha, size: 30)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: desbloqueado ? AppColors.textDark : Colors.grey.shade600))), 
                    const SizedBox(width: 6), 
                    if (desbloqueado) const Icon(Icons.verified, color: AppColors.primarySage, size: 18)
                  ]
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
