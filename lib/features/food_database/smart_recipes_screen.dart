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

  // Banco de Dados Local Simulado (Até migrarmos as 100+ para a nuvem)
  final List<Map<String, dynamic>> _todasReceitas = [
    {'nome': 'Panqueca de Aveia', 'ingredientes': 'Ovos, Aveia, Banana e Canela', 'kcal': 250, 'c': 30.0, 'p': 15.0, 'g': 8.0, 'icone': Icons.breakfast_dining, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Pizza Fit de Frigideira', 'ingredientes': 'Rap10, Molho, Queijo Magro e Frango', 'kcal': 320, 'c': 25.0, 'p': 28.0, 'g': 12.0, 'icone': Icons.local_pizza, 'objetivo_foco': 'Emagrecimento'},
    {'nome': 'Vitamina Hipercalórica', 'ingredientes': 'Leite, Banana, Pasta de Amendoim, Whey', 'kcal': 650, 'c': 60.0, 'p': 40.0, 'g': 25.0, 'icone': Icons.local_drink, 'objetivo_foco': 'Hipertrofia'},
    {'nome': 'Bowl de Salmão e Abacate', 'ingredientes': 'Salmão, Abacate, Arroz, Gergelim', 'kcal': 450, 'c': 30.0, 'p': 35.0, 'g': 20.0, 'icone': Icons.set_meal, 'objetivo_foco': 'Saúde & Longevidade'},
    {'nome': 'Crepioca Nutritiva', 'ingredientes': 'Ovos, Tapioca, Espinafre e Queijo', 'kcal': 280, 'c': 22.0, 'p': 25.0, 'g': 9.0, 'icone': Icons.egg_alt, 'objetivo_foco': 'Gestante ou Tentante'},
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

          // Descobre o objetivo do paciente no Firebase
          final dadosUser = snapshot.data!.data() as Map<String, dynamic>?;
          final objetivoPaciente = dadosUser?['objetivo'] ?? 'Emagrecimento';

          // Filtra as receitas baseadas no objetivo (e adiciona algumas gerais para não ficar vazio)
          final receitasFiltradas = _todasReceitas.where((r) => 
            r['objetivo_foco'] == objetivoPaciente || r['objetivo_foco'] == 'Emagrecimento'
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Foco: $objetivoPaciente 🎯', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text('Receitas selecionadas especialmente para o seu projeto de saúde.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
              
              const SizedBox(height: 80), // Espaço para não esconder atrás do botão flutuante
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
