import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class SmartRecipesScreen extends StatelessWidget {
  const SmartRecipesScreen({Key? key}) : super(key: key);

  void _consumirReceita(BuildContext context, String nome, int kcal, double carbos, double prot, double gord) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataHoje);

    await docRef.set({
      'calorias_consumidas': FieldValue.increment(kcal),
      'carbos_consumidos': FieldValue.increment(carbos),
      'proteinas_consumidos': FieldValue.increment(prot),
      'gorduras_consumidos': FieldValue.increment(gord),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': "🍳 Receita Smart: $nome",
          'turno': 'Lanche', // Padrão, pode ser editado pelo usuário depois
          'quantidade': 1.0,
          'medida_escolhida': '1 Porção Completa',
          'calorias': kcal,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚡ $nome adicionado ao diário!'), backgroundColor: AppColors.primarySage));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Receitas Fit (1 Clique)', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Cozinhe e Registre 🧑‍🍳', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('Esqueça a contagem manual. Fez a receita? Clique em "Eu comi isso" e nós calculamos tudo.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),

          _buildRecipeCard(context, 'Panqueca de Aveia', 'Ovos, Aveia, Banana e Canela', 250, 30.0, 15.0, 8.0, Icons.breakfast_dining),
          _buildRecipeCard(context, 'Pizza Fit de Frigideira', 'Rap10, Molho, Queijo Magro e Frango', 320, 25.0, 28.0, 12.0, Icons.local_pizza),
          _buildRecipeCard(context, 'Crepioca de Frango', 'Ovos, Tapioca, Frango Desfiado', 280, 22.0, 25.0, 9.0, Icons.egg_alt),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, String nome, String ingredientes, int kcal, double c, double p, double g, IconData icone) {
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
              onPressed: () => _consumirReceita(context, nome, kcal, c, p, g),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Eu Comi Isso (1 Clique)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
