import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class SmartRecipesScreen extends StatefulWidget {
  const SmartRecipesScreen({Key? key}) : super(key: key);

  @override
  State<SmartRecipesScreen> createState() => _SmartRecipesScreenState();
}

class _SmartRecipesScreenState extends State<SmartRecipesScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  // 🔥 BANCO DE DADOS EXPANDIDO COM DEZENAS DE OPÇÕES PRONTAS POR OBJETIVO
  final List<Map<String, dynamic>> _todasReceitas = [
    // 🍏 EMAGRECIMENTO
    {'nome': 'Panqueca de Aveia', 'ingredientes': 'Ovos, Aveia, Banana e Canela', 'kcal': 250, 'c': 30.0, 'p': 15.0, 'g': 8.0, 'icone': Icons.breakfast_dining, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Pizza Fit de Frigideira', 'ingredientes': 'Rap10, Molho, Queijo Magro e Frango', 'kcal': 320, 'c': 25.0, 'p': 28.0, 'g': 12.0, 'icone': Icons.local_pizza, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Omelete de Claras Sem Óleo', 'ingredientes': '3 Claras, 1 Ovo, Tomate, Cebola, Espinafre', 'kcal': 140, 'c': 4.0, 'p': 18.0, 'g': 6.0, 'icone': Icons.egg, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Sopa Creme de Abóbora com Frango', 'ingredientes': 'Abóbora Cabotiá, Peito de Frango Desfiado', 'kcal': 210, 'c': 15.0, 'p': 24.0, 'g': 4.0, 'icone': Icons.soup_kitchen, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Mousse de Whey de Chocolate', 'ingredientes': 'Whey Protein, Iogurte Desnatado, Cacau', 'kcal': 160, 'c': 8.0, 'p': 26.0, 'g': 2.0, 'icone': Icons.icecream, 'objetivo_foco': 'Emagrecimento'},

    // 💪 HIPERTROFIA
    {'nome': 'Vitamina Hipercalórica Pro', 'ingredientes': 'Leite Inteiro, Banana, Pasta de Amendoim, Whey', 'kcal': 680, 'c': 65.0, 'p': 42.0, 'g': 24.0, 'icone': Icons.local_drink, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Arroz Termogênico com Patinho', 'ingredientes': 'Arroz Parboilizado, Patinho Moído, Azeite', 'kcal': 550, 'c': 55.0, 'p': 40.0, 'g': 14.0, 'icone': Icons.rice_bowl, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Macarrão Fake Integral com Atum', 'ingredientes': 'Macarrão Integral, Atum Ralado, Creme de Leite Leve', 'kcal': 490, 'c': 48.0, 'p': 35.0, 'g': 12.0, 'icone': Icons.dinner_dining, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Panqueca Monstro de Batata Doce', 'ingredientes': 'Batata Doce Cozida, 3 Ovos, Whey isolado', 'kcal': 430, 'c': 40.0, 'p': 32.0, 'g': 11.0, 'icone': Icons.cake, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Mingau de Aveia Giga', 'ingredientes': 'Aveia em Flocos, Leite de Amêndoas, Whey, Mel', 'kcal': 390, 'c': 50.0, 'p': 28.0, 'g': 6.0, 'icone': Icons.bakery_dining, 'objetivo_foco': 'Hipertrofia'},

    // 👶 GESTANTE OU TENTANTE
    {'nome': 'Crepioca Nutritiva de Espinafre', 'ingredientes': 'Ovos, Tapioca, Espinafre e Queijo Branco', 'kcal': 280, 'c': 22.0, 'p': 25.0, 'g': 9.0, 'icone': Icons.egg_alt, 'objetivo_foco': 'Gestante ou Tentante'},
    {'nome': 'Iogurte da Mamãe C/ Chia', 'ingredientes': 'Iogurte Natural, Chia, Morangos, Castanhas', 'kcal': 220, 'c': 18.0, 'p': 10.0, 'g': 12.0, 'icone': Icons.breakfast_dining, 'objetivo_foco': 'Gestante ou Tentante'},
    {'nome': 'Sanduíche Integral de Ferro', 'ingredientes': 'Pão Integral, Ricota Temperada, Cenoura, Agrião', 'kcal': 240, 'c': 26.0, 'p': 12.0, 'g': 7.0, 'icone': Icons.lunch_dining, 'objetivo_foco': 'Gestante ou Tentante'},

    // 🧬 SAÚDE & LONGEVIDADE
    {'nome': 'Bowl de Salmão e Abacate', 'ingredientes': 'Salmão Grelhado, Abacate, Arroz Integral', 'kcal': 450, 'c': 30.0, 'p': 35.0, 'g': 20.0, 'icone': Icons.set_meal, 'objetivo_foco': 'Saúde & Longevidade'},
    {'nome': 'Mix Antioxidante Funcional', 'ingredientes': 'Kefir, Mirtilo, Framboesa, Semente de Girassol', 'kcal': 190, 'c': 16.0, 'p': 8.0, 'g': 9.0, 'icone': Icons.local_pharmacy, 'objetivo_foco': 'Saúde & Longevidade'},
    {'nome': 'Salada de Grão de Bico Viva', 'ingredientes': 'Grão de Bico, Tomate Cereja, Pepino, Azeite Extra Virgem', 'kcal': 260, 'c': 28.0, 'p': 11.0, 'g': 10.0, 'icone': Icons.salad, 'objetivo_foco': 'Saúde & Longevidade'},
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
          'nome': "🍳 Receita Smart: $nome",
          'turno': 'Lanche',
          'quantidade': 1.0,
          'medida_escolhida': '1 Porção Completa',
          'calorias': kcal,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚡ $nome adicionado ao diário!'), backgroundColor: AppColors.primarySage));
      Navigator.pop(context);
    }
  }

  void _abrirDialogCriarReceita() {
    final nomeCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final carbosCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final gordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Nova Receita', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome da Receita')),
              TextField(controller: kcalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorias Totais (kcal)')),
              TextField(controller: carbosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carboidratos (g)')),
              TextField(controller: protCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Proteínas (g)')),
              TextField(controller: gordCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gorduras (g)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage),
            onPressed: () {
              if (nomeCtrl.text.isNotEmpty && kcalCtrl.text.isNotEmpty) {
                _consumirReceita(
                  nomeCtrl.text,
                  int.tryParse(kcalCtrl.text) ?? 0,
                  double.tryParse(carbosCtrl.text) ?? 0.0,
                  double.tryParse(protCtrl.text) ?? 0.0,
                  double.tryParse(gordCtrl.text) ?? 0.0,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar e Consumir', style: TextStyle(color: Colors.white)),
          ),
        ],
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
        icon: const Icon(Icons.add, color: Colors.white),
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

          // Filtra exibindo receitas do objetivo + algumas genéricas para variedade
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
