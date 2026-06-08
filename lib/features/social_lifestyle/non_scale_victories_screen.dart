import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class NonScaleVictoriesScreen extends StatefulWidget {
  const NonScaleVictoriesScreen({Key? key}) : super(key: key);

  @override
  State<NonScaleVictoriesScreen> createState() => _NonScaleVictoriesScreenState();
}

class _NonScaleVictoriesScreenState extends State<NonScaleVictoriesScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  // Chave de data para salvar as conquistas com base no dia de hoje
  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  // Lista mestre de conquistas premium monitoradas pela plataforma
  final List<Map<String, dynamic>> _conquistasMestre = [
    {
      'id': 'energia_alta',
      'titulo': 'Energia Constante',
      'descricao': 'Sem aquele cansaço ou sono forte após o almoço.',
      'icone': Icons.bolt_rounded,
      'cor': Colors.amber,
    },
    {
      'id': 'sono_reparador',
      'titulo': 'Sono de Qualidade',
      'descricao': 'Dormiu rápido e acordou com a sensação de descanso.',
      'icone': Icons.hotel_rounded,
      'cor': Colors.indigo,
    },
    {
      'id': 'roupa_solta',
      'titulo': 'Roupas Mais Largar',
      'descricao': 'Sentiu aquela calça ou camisa vestindo de forma mais confortável.',
      'icone': Icons.checkroom_rounded,
      'cor': AppColors.accentPeach,
    },
    {
      'id': 'foco_afiado',
      'titulo': 'Foco e Clareza Mental',
      'descricao': 'Maior produtividade e menos névoa mental ao longo do dia.',
      'icone': Icons.psychology_rounded,
      'cor': Colors.purple,
    },
    {
      'id': 'digestao_nota_10',
      'titulo': 'Intestino Regulado',
      'descricao': 'Digestão leve, sem estufamento ou desconforto gástrico.',
      'icone': Icons.health_and_safety_rounded,
      'cor': AppColors.secondaryMenta,
    },
    {
      'id': 'controle_doce',
      'titulo': 'Domou o Açúcar',
      'descricao': 'Passou o dia sem aquela vontade incontrolável de comer doces.',
      'icone': Icons.cookie_rounded,
      'cor': Colors.orange,
    },
  ];

  // 🔥 Atualiza o estado da conquista diretamente no Cloud Firestore
  void _alternarConquista(String idConquista, bool statusAtual, String dataKey) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('conquistas')
        .doc(dataKey);

    await docRef.set({
      idConquista: !statusAtual, // Inverte o estado booleano
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final dataKey = _getTodayDateKey();

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Minhas Conquistas'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_userId)
            .collection('conquistas')
            .doc(dataKey)
            .snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> conquistasSalvas = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            conquistasSalvas = snapshot.data!.data() as Map<String, dynamic>;
          }

          // Calcula a porcentagem de conquistas batidas hoje para a barra de progresso
          int totalBatido = conquistasSalvas.values.where((v) => v == true).length;
          double progressoDiario = _conquistasMestre.isEmpty ? 0 : totalBatido / _conquistasMestre.length;

          return Column(
            children: [
              // 1. HEADER EMOCIONAL E PROGRESSO
              Container(
                color: AppColors.primarySage,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Evolução Além do Peso 🌿',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Marque as vitórias que você sentiu no seu corpo hoje.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progressoDiario,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.secondaryMenta,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalBatido de ${_conquistasMestre.length} conquistados hoje!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primarySage),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. GRADE DE CARDS DAS VITÓRIAS
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conquistasMestre.length,
                  itemBuilder: (context, index) {
                    final item = _conquistasMestre[index];
                    final String id = item['id'];
                    final bool isConquistado = conquistasSalvas[id] ?? false;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isConquistado ? AppColors.primarySage.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isConquistado ? AppColors.primarySage : Colors.grey.shade200,
                          width: isConquistado ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _alternarConquista(id, isConquistado, dataKey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item['cor'].withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icone'], color: item['cor'], size: 26),
                        ),
                        title: Text(
                          item['titulo'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item['descricao'],
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                          ),
                        ),
                        trailing: Icon(
                          isConquistado ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isConquistado ? AppColors.primarySage : Colors.grey.shade300,
                          size: 26,
                        ),
                      ),
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
