import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/patient_hub/profile_screen.dart';
import 'package:nutri_life/features/patient_hub/fasting_screen.dart';
import 'package:nutri_life/features/patient_hub/grocery_list_screen.dart';
import 'package:nutri_life/features/patient_hub/evolution_gallery_screen.dart';
import 'package:nutri_life/features/patient_hub/habits_screen.dart';
import 'package:nutri_life/features/patient_hub/bmi_stats_screen.dart';          
import 'package:nutri_life/features/food_database/smart_recipes_screen.dart'; 
import 'package:nutri_life/features/chat/chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  void _abrirDialogoRegistrarPeso(BuildContext context) {
    final txtController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Peso Atual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: TextField(
          controller: txtController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Ex: 78.5', suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage),
            onPressed: () async {
              if (txtController.text.isNotEmpty) {
                double? pesoDigitado = double.tryParse(txtController.text.replaceAll(',', '.'));
                if (pesoDigitado != null) {
                  final dataKey = _getTodayDateKey();
                  await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('historico_peso').doc(dataKey).set({
                    'peso': pesoDigitado, 'data': dataKey, 'timestamp': DateTime.now().millisecondsSinceEpoch
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _construirMotorDeInsights(int consumido, int meta, int queimado, String objetivo) {
    String mensagem = "Tudo no caminho certo! Mantenha o foco na sua estratégia hoje. 🚀";
    IconData icone = Icons.auto_awesome;
    Color corTexto = AppColors.primarySage;

    if (queimado > 0 && objetivo == 'Hipertrofia') {
      mensagem = "Você queimou $queimado kcal treinando! Lembre-se de comer bem para garantir o ganho de massa. 💪";
      icone = Icons.fitness_center;
      corTexto = Colors.orangeAccent.shade700;
    } else if (queimado > 0 && objetivo == 'Emagrecimento') {
      mensagem = "Sensacional! Mais $queimado kcal gastas. Você acelerou o seu déficit calórico hoje! 🔥";
      icone = Icons.local_fire_department;
      corTexto = AppColors.accentPeach;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: corTexto.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icone, color: corTexto, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(mensagem, style: TextStyle(color: corTexto, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = _getTodayDateKey();

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Painel', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 26, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('usuarios').doc(_userId).get(),
        builder: (context, userSnapshot) {
          String objetivo = 'Emagrecimento';
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final dadosUser = userSnapshot.data!.data() as Map<String, dynamic>?;
            objetivo = dadosUser?['objetivo'] ?? 'Emagrecimento';
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
            builder: (context, snapshot) {
              int consumido = 0, meta = 2000, queimado = 0;
              double carbos = 0, proteinas = 0, gorduras = 0;

              if (snapshot.hasData && snapshot.data!.exists) {
                final dados = snapshot.data!.data() as Map<String, dynamic>;
                consumido = dados['calorias_consumidas'] ?? 0;
                meta = dados['meta_calorias'] ?? (objetivo == 'Hipertrofia' ? 2600 : 2000);
                queimado = dados['calorias_queimadas'] ?? 0;
                carbos = (dados['carbos_consumidos'] ?? 0).toDouble();
                proteinas = (dados['proteinas_consumidos'] ?? 0).toDouble();
                gorduras = (dados['gorduras_consumidos'] ?? 0).toDouble();
              }

              int restante = (meta - consumido + queimado).clamp(0, 9999);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foco: $objetivo 🎯', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    
                    _construirMotorDeInsights(consumido, meta, queimado, objetivo),
                    
                    _CardCaloriasPremium(
                      consumido: consumido, meta: meta, restante: restante, 
                      queimado: queimado, carbos: carbos, proteinas: proteinas, 
                      gorduras: gorduras, objetivo: objetivo
                    ),
                    const SizedBox(height: 24),
                    
                    _construirBotaoPeso(),
                    const SizedBox(height: 24),
                    const Text('Ferramentas de Acompanhamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 16),
                    
                    // 🚀 RETORNO DO GRID COMPLETO DE 6 BOTÕES
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _cardTool(Icons.restaurant_menu, 'Receitas Fit', 'Cardápio Inteligente', AppColors.primarySage, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartRecipesScreen()))),
                        _cardTool(Icons.timer_outlined, 'Jejum Intermitente', 'Cronômetro', AppColors.accentPeach, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FastingScreen()))),
                        _cardTool(Icons.shopping_cart_outlined, 'Lista de Compras', 'Organizador', AppColors.secondaryMenta, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryListScreen()))),
                        _cardTool(Icons.collections_outlined, 'Fotos de Evolução', 'Galeria 3x3', Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EvolutionGalleryScreen()))),
                        _cardTool(Icons.check_box_outlined, 'Rotina diária', 'Hábitos Fixos', Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen()))),
                        _cardTool(Icons.analytics_outlined, 'Estatísticas IMC', 'Histórico Clínico', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BmiStatsScreen()))),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _construirBotaoPeso() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Evolução de Peso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)), Text('Mantenha seu peso atualizado', style: TextStyle(fontSize: 12, color: Colors.grey))]),
          ElevatedButton(onPressed: () => _abrirDialogoRegistrarPeso(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage), child: const Text('Pesar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _cardTool(IconData icone, String tit, String sub, Color cor, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E2126), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 8),
            Text(tit, style: const TextStyle(color: Colors.white, grandmother: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11))
          ]
        ),
      ),
    );
  }
}

class _CardCaloriasPremium extends StatelessWidget {
  final int consumido, meta, restante, queimado;
  final double carbos, proteinas, gorduras;
  final String objetivo;
  
  const _CardCaloriasPremium({Key? key, required this.consumido, required this.meta, required this.restante, required this.queimado, required this.carbos, required this.proteinas, required this.gorduras, required this.objetivo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progresso = consumido / (meta + queimado);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(children: [Text('$consumido', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Text('Comido', style: TextStyle(fontSize: 12, color: Colors.grey))]),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 110, height: 110, child: CircularProgressIndicator(value: progresso.clamp(0.0, 1.0), strokeWidth: 10, backgroundColor: Colors.grey.shade100, color: objetivo == 'Hipertrofia' ? AppColors.secondaryMenta : AppColors.primarySage)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$restante', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(objetivo == 'Hipertrofia' ? 'Faltam' : 'Restam', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Column(children: [Text('$queimado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)), const Text('Treino', style: TextStyle(fontSize: 12, color: Colors.grey))]),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macro('Carbos', carbos, objetivo == 'Hipertrofia' ? 300 : 200, AppColors.secondaryMenta),
              _macro('Proteínas', proteinas, objetivo == 'Hipertrofia' ? 180 : 130, AppColors.primarySage),
              _macro('Gorduras', gorduras, objetivo == 'Hipertrofia' ? 80 : 65, AppColors.accentPeach),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(String nome, double atual, double alvo, Color cor) {
    return Column(
      children: [
        Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Container(width: 65, height: 6, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (atual / alvo).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(10))))),
        const SizedBox(height: 6),
        Text('${atual.toInt()}/${alvo.toInt()}g', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
