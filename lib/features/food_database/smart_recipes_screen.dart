import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SmartRecipesScreen extends StatefulWidget {
  const SmartRecipesScreen({Key? key}) : super(key: key);

  @override
  State<SmartRecipesScreen> createState() => _SmartRecipesScreenState();
}

class _SmartRecipesScreenState extends State<SmartRecipesScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  
  // 🔐 Chave da API dividida
  static const String _parte1 = 'AQ.Ab8RN6KUudctvJp-';
  static const String _parte2 = 'ev1vDI5G1Ma4iFmAe1h9nxs4j2Yeost50A';
  final String _apiKey = _parte1 + _parte2;

  final List<Map<String, dynamic>> _todasReceitas = [
    // 🍏 EMAGRECIMENTO
    {'nome': 'Panqueca de Aveia', 'ingredientes': 'Ovos, Aveia, Banana e Canela', 'kcal': 250, 'c': 30.0, 'p': 15.0, 'g': 8.0, 'icone': Icons.breakfast_dining, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Pizza Fit de Frigideira', 'ingredientes': 'Rap10, Molho, Queijo Magro e Frango', 'kcal': 320, 'c': 25.0, 'p': 28.0, 'g': 12.0, 'icone': Icons.local_pizza, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Omelete de Claras Sem Óleo', 'ingredientes': '3 Claras, 1 Ovo, Tomate, Cebola, Espinafre', 'kcal': 140, 'c': 4.0, 'p': 18.0, 'g': 6.0, 'icone': Icons.egg, 'objetivo_foco': 'Emagrecimento'},
    
    // 💪 HIPERTROFIA
    {'nome': 'Vitamina Hipercalórica Pro', 'ingredientes': 'Leite Inteiro, Banana, Pasta de Amendoim, Whey', 'kcal': 680, 'c': 65.0, 'p': 42.0, 'g': 24.0, 'icone': Icons.local_drink, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Arroz Termogênico com Patinho', 'ingredientes': 'Arroz Parboilizado, Patinho Moído, Azeite', 'kcal': 550, 'c': 55.0, 'p': 40.0, 'g': 14.0, 'icone': Icons.rice_bowl, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Panqueca Monstro de Batata Doce', 'ingredientes': 'Batata Doce Cozida, 3 Ovos, Whey isolado', 'kcal': 430, 'c': 40.0, 'p': 32.0, 'g': 11.0, 'icone': Icons.cake, 'objetivo_foco': 'Hipertrofia'},

    // 👶 GESTANTE OU TENTANTE
    {'nome': 'Crepioca Nutritiva de Espinafre', 'ingredientes': 'Ovos, Tapioca, Espinafre e Queijo Branco', 'kcal': 280, 'c': 22.0, 'p': 25.0, 'g': 9.0, 'icone': Icons.egg_alt, 'objetivo_foco': 'Gestante ou Tentante'},
    {'nome': 'Iogurte da Mamãe C/ Chia', 'ingredientes': 'Iogurte Natural, Chia, Morangos, Castanhas', 'kcal': 220, 'c': 18.0, 'p': 10.0, 'g': 12.0, 'icone': Icons.breakfast_dining, 'objetivo_foco': 'Gestante ou Tentante'},

    // 🧬 SAÚDE & LONGEVIDADE
    {'nome': 'Bowl de Salmão e Abacate', 'ingredientes': 'Salmão Grelhado, Abacate, Arroz Integral', 'kcal': 450, 'c': 30.0, 'p': 35.0, 'g': 20.0, 'icone': Icons.set_meal, 'objetivo_foco': 'Saúde & Longevidade'},
    {'nome': 'Mix Antioxidante Funcional', 'ingredientes': 'Kefir, Mirtilo, Framboesa, Semente de Girassol', 'kcal': 190, 'c': 16.0, 'p': 8.0, 'g': 9.0, 'icone': Icons.local_pharmacy, 'objetivo_foco': 'Saúde & Longevidade'},
  ];

  void _consumirReceita(String nome, int kcal, double carbos, double prot, double gord) async {
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje);

    await docRef.set({
      'calorias_consumidas': FieldValue.increment(kcal),
      'carbos_consumidos': FieldValue.increment(carbos),
      'proteinas_consumidos': FieldValue.increment(prot),
      'gorduras_consumidos': FieldValue.increment(gord),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': "🍳 Receita: $nome",
          'turno': 'Refeição Extra',
          'quantidade': 1.0,
          'medida_escolhida': '1 Porção',
          'calorias': kcal,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚡ $nome adicionado ao diário!'), backgroundColor: AppColors.primarySage));
    }
  }

  // 🚀 PONTO 1: MODAL INTELIGENTE DE CRIAÇÃO DE RECEITA
  void _abrirDialogCriarReceita() {
    final nomeCtrl = TextEditingController();
    final ingredientesCtrl = TextEditingController();
    bool calculando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24, left: 24, right: 24
            ),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primarySage),
                    SizedBox(width: 8),
                    Text('Criar Receita Inteligente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Diga os ingredientes e nossa IA calculará os macros automaticamente para o seu diário.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: 'Nome da Receita (Ex: Panqueca de Whey)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: ingredientesCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Ingredientes com quantidades', 
                    hintText: 'Ex: 2 ovos, 30g de aveia, 1 colher de mel...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: calculando ? null : () async {
                      if (nomeCtrl.text.isEmpty || ingredientesCtrl.text.isEmpty) return;
                      setStateModal(() => calculando = true);

                      try {
                        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
                        final prompt = "Atue como nutricionista. Estime as calorias e macronutrientes totais desta receita. Nome: ${nomeCtrl.text}. Ingredientes: ${ingredientesCtrl.text}. Retorne APENAS um objeto JSON válido com este formato exato, sem formatação markdown: {\"kcal\": 250, \"c\": 30.0, \"p\": 15.0, \"g\": 8.0}";

                        final response = await http.post(
                          url,
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({"contents": [{"parts": [{"text": prompt}]}]}),
                        );

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          String raw = data['candidates'][0]['content']['parts'][0]['text'];
                          raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
                          
                          final macros = jsonDecode(raw);
                          
                          _consumirReceita(
                            nomeCtrl.text.trim(), 
                            (macros['kcal'] as num).toInt(), 
                            (macros['c'] as num).toDouble(), 
                            (macros['p'] as num).toDouble(), 
                            (macros['g'] as num).toDouble()
                          );

                          if (mounted) Navigator.pop(context);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao calcular. Verifique a conexão.'), backgroundColor: Colors.red));
                      } finally {
                        setStateModal(() => calculando = false);
                      }
                    },
                    child: calculando 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Calcular IA e Consumir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Receitas Fit', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogCriarReceita,
        backgroundColor: AppColors.primarySage,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Criar Receita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('usuarios').doc(_userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
          }

          final dadosUser = snapshot.data!.data() as Map<String, dynamic>?;
          final objetivoPaciente = dadosUser?['objetivo'] ?? 'Emagrecimento';

          final receitasFiltradas = _todasReceitas.where((r) => 
            r['objetivo_foco'] == objetivoPaciente || r['objetivo_foco'] == 'Emagrecimento'
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Foco: $objetivoPaciente 🎯', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text('Sugestões calculadas exclusivamente para o seu perfil.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 24),
              
              ...receitasFiltradas.map((receita) => _buildRecipeCard(
                receita['nome'], 
                receita['ingredientes'], 
                receita['kcal'], 
                receita['c'], 
                receita['p'], 
                receita['g'], 
                receita['icone']
              )).toList(),
              
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(String nome, String ingredientes, int kcal, double c, double p, double g, IconData icone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primarySage.withOpacity(0.1), child: Icon(icone, color: AppColors.primarySage)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                    Text(ingredientes, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🔥 $kcal kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentPeach)),
              Text('C: ${c.toInt()}g | P: ${p.toInt()}g | G: ${g.toInt()}g', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _consumirReceita(nome, kcal, c, p, g),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Eu Comi Isso (1 Clique)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
