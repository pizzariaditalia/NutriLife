import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/patient_hub/profile_screen.dart';
import 'package:nutri_life/features/patient_hub/fasting_screen.dart';
import 'package:nutri_life/features/grocery_list_screen.dart';
import 'package:nutri_life/features/patient_hub/evolution_gallery_screen.dart';
import 'package:nutri_life/features/patient_hub/habits_screen.dart';
import 'package:nutri_life/features/patient_hub/bmi_stats_screen.dart';          
import 'package:nutri_life/features/food_database/smart_recipes_screen.dart'; 
import 'package:nutri_life/features/chat/chat_screen.dart';
import 'package:nutri_life/features/food_database/food_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  
  // Variáveis para fazer o Feed de teste funcionar na hora
  bool _curtiuEstatico = false;
  int _qtdCurtidasEstaticas = 24;
  final List<String> _comentariosEstaticos = [
    'Caraca, não sabia disso! Vou testar hoje.',
    'Dica top demais, Ana!'
  ];

  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  void _adicionarAgua() async {
    final dataHoje = _getTodayDateKey();
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('diario')
        .doc(dataHoje)
        .set({'agua_consumida': FieldValue.increment(250)}, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💧 Ótimo! +250ml de pura hidratação. 🚀'), backgroundColor: Colors.blue),
      );
    }
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

                  await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set({
                    'peso_atual': pesoDigitado
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚖️ Peso atualizado!'), backgroundColor: AppColors.primarySage)
                    );
                  }
                }
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _alternarCurtidaPost(String postId, List<dynamic> curtidas) async {
    final docRef = FirebaseFirestore.instance.collection('feed').doc(postId);
    if (curtidas.contains(_userId)) {
      await docRef.update({'curtidas': FieldValue.arrayRemove([_userId])});
    } else {
      await docRef.update({'curtidas': FieldValue.arrayUnion([_userId])});
    }
  }

  void _abrirAbasComentarios(String postId) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comentários 💬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('feed').doc(postId).collection('comentarios').orderBy('timestamp', descending: false).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Seja o primeiro a comentar!', style: TextStyle(color: Colors.grey))));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (context, i) {
                      final c = snap.data!.docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c['autor'] ?? 'Paciente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(c['texto'] ?? '', style: const TextStyle(color: AppColors.textDark)),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(hintText: 'Escreva um comentário...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primarySage),
                    onPressed: () async {
                      if (commentCtrl.text.trim().isEmpty) return;
                      await FirebaseFirestore.instance.collection('feed').doc(postId).collection('comentarios').add({
                        'texto': commentCtrl.text.trim(),
                        'autor': 'Paciente Ativo',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      commentCtrl.clear();
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // 💬 COMENTÁRIOS DA POSTAGEM DE TESTE LOCAL
  void _abrirComentariosEstaticos() {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Comentários do Post 💬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _comentariosEstaticos.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Paciente Focado 💪', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(_comentariosEstaticos[i], style: const TextStyle(color: AppColors.textDark)),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(hintText: 'Escreva seu comentário...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primarySage),
                      onPressed: () {
                        if (commentCtrl.text.trim().isEmpty) return;
                        setState(() {
                          _comentariosEstaticos.add(commentCtrl.text.trim());
                        });
                        setModalState(() {}); // Atualiza o modal na hora
                        commentCtrl.clear();
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPostEstatico() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primarySage.withOpacity(0.2), child: const Icon(Icons.stars, color: AppColors.primarySage)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Nutricionista Ana Silva 👑', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)), Text('Canal de Dicas', style: TextStyle(color: Colors.grey, fontSize: 11))])
            ],
          ),
          const SizedBox(height: 12),
          const Text('Dica de ouro: O consumo de água gelada antes dos treinos ajuda na regulação térmica e aumenta a performance metabólica em até 12%. Não pulem a hidratação!', style: TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Row(
            children: [
              // 🚀 CORREÇÃO CURTIDA: Agora muda de estado e soma localmente na hora!
              IconButton(
                icon: Icon(_curtiuEstatico ? Icons.favorite : Icons.favorite_border, color: _curtiuEstatico ? Colors.red : Colors.grey),
                onPressed: () {
                  setState(() {
                    _curtiuEstatico = !_curtiuEstatico;
                    _qtdCurtidasEstaticas += _curtiuEstatico ? 1 : -1;
                  });
                },
              ),
              Text('$_qtdCurtidasEstaticas curtidas', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 24),
              // 🚀 CORREÇÃO COMENTÁRIO: Abre a caixa interativa funcional
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 22),
                onPressed: _abrirComentariosEstaticos,
              ),
              Text('${_comentariosEstaticos.length} comentários', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = _getTodayDateKey();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).snapshots(),
      builder: (context, userSnapshot) {
        String objetivo = 'Emagrecimento';
        String? fotoPerfilUrl;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final dadosUser = userSnapshot.data!.data() as Map<String, dynamic>?;
          objetivo = dadosUser?['objetivo'] ?? 'Emagrecimento';
          fotoPerfilUrl = dadosUser?['foto_perfil'];
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundCreme,
          appBar: AppBar(
            title: const Text('Meu Painel', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.primarySage,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, size: 26, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodSearchScreen(turno: 'Geral'))),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 26, color: Colors.white),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma notificação nova. 🔔'))),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    backgroundImage: fotoPerfilUrl != null ? NetworkImage(fotoPerfilUrl) : null,
                    child: fotoPerfilUrl == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
                  ),
                ),
              )
            ],
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
            builder: (context, snapshot) {
              int consumido = 0, meta = 2000, queimado = 0, agua = 0;
              double carbos = 0, proteinas = 0, gorduars = 0;

              if (snapshot.hasData && snapshot.data!.exists) {
                final dados = snapshot.data!.data() as Map<String, dynamic>;
                consumido = dados['calorias_consumidas'] ?? 0;
                meta = dados['meta_calorias'] ?? (objetivo == 'Hipertrofia' ? 2600 : 2000);
                queimado = dados['calorias_queimadas'] ?? 0;
                agua = dados['agua_consumida'] ?? 0;
                carbos = (dados['carbos_consumidos'] ?? 0).toDouble();
                proteinas = (dados['proteinas_consumidos'] ?? 0).toDouble();
                gorduars = (dados['gorduras_consumidos'] ?? 0).toDouble();
              }

              int restante = (meta - consumido + queimado).clamp(0, 9999);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foco: $objetivo 🎯', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    
                    _CardCaloriasPremium(
                      consumido: consumido, meta: meta, restante: restante, 
                      queimado: queimado, carbos: carbos, proteinas: proteinas, 
                      gorduras: gorduars, objetivo: objetivo
                    ),
                    const SizedBox(height: 24),
                    
                    _construirRastreadorAgua(agua),
                    _construirBotaoPeso(),
                    const SizedBox(height: 24),
                    
                    const Text('Ferramentas de Acompanhamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 16),
                    
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
                    const SizedBox(height: 28),

                    const Text('Feed da Comunidade 📣', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('feed').orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, feedSnap) {
                        if (!feedSnap.hasData || feedSnap.data!.docs.isEmpty) {
                          return _buildCardPostEstatico();
                        }

                        return Column(
                          children: feedSnap.data!.docs.map((doc) {
                            final post = doc.data() as Map<String, dynamic>;
                            final List<dynamic> curtidas = post['curtidas'] ?? [];
                            final bool euCurti = curtidas.contains(_userId);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(backgroundColor: AppColors.primarySage.withOpacity(0.2), child: const Icon(Icons.stars, color: AppColors.primarySage)),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(post['autor'] ?? 'Nutricionista 👑', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
                                          const Text('Post Oficial', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(post['texto'] ?? '', style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(euCurti ? Icons.favorite : Icons.favorite_border, color: euCurti ? Colors.red : Colors.grey),
                                        onPressed: () => _alternarCurtidaPost(doc.id, curtidas),
                                      ),
                                      Text('${curtidas.length} curtidas', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      const SizedBox(width: 24),
                                      IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 22),
                                        onPressed: () => _abrirAbasComentarios(doc.id),
                                      ),
                                      const Text('Comentar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        );
      },
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
            Text(tit, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11))
          ],
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
