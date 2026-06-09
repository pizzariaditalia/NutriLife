import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({Key? key}) : super(key: key);

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final TextEditingController _itemController = TextEditingController();

  // ➕ ADICIONAR ITEM NA LISTA
  void _adicionarItem() async {
    if (_itemController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('lista_compras')
        .add({
      'nome': _itemController.text.trim(),
      'comprado': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _itemController.clear();
  }

  // ✅ MARCAR COMO COMPRADO
  void _alternarStatusItem(String docId, bool statusAtual) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('lista_compras')
        .doc(docId)
        .update({'comprado': !statusAtual});
  }

  // 🗑️ DELETAR ITEM
  void _deletarItem(String docId) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('lista_compras')
        .doc(docId)
        .delete();
  }

  // 🍏 CONSULTAR DIETA DA NUTRI NO MERCADO
  void _mostrarDietaPrescrita() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_userId).get();
    Map<String, dynamic> plano = {};
    if (doc.exists && doc.data() != null) {
      plano = doc.data()!['plano_alimentar'] ?? {};
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prescrição da Nutri 📝', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primarySage)),
              const SizedBox(height: 8),
              Text('Baseie suas compras nesta dieta:', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _blocoDieta('☕ Café da Manhã', plano['cafe']),
                    _blocoDieta('☀️ Almoço', plano['almoco']),
                    _blocoDieta('🍌 Lanche', plano['lanche']),
                    _blocoDieta('🌙 Jantar', plano['jantar']),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Fechar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  Widget _blocoDieta(String titulo, String? texto) {
    if (texto == null || texto.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.backgroundCreme, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text(texto, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in_rounded),
            tooltip: 'Ver Dieta',
            onPressed: _mostrarDietaPrescrita,
          ),
        ],
      ),
      body: Column(
        children: [
          // CABEÇALHO DE INSERÇÃO
          Container(
            color: AppColors.primarySage,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Adicionar produto (ex: Aveia)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _adicionarItem(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppColors.primarySage),
                    onPressed: _adicionarItem,
                  ),
                ),
              ],
            ),
          ),
          
          // LISTA REATIVA DO FIREBASE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(_userId)
                  .collection('lista_compras')
                  .orderBy('comprado') // Ordena: falsos (pendentes) primeiro
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
                
                final itens = snapshot.data!.docs;
                if (itens.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Sua lista está vazia.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    final bool comprado = item['comprado'];
                    
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => _deletarItem(item.id),
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: comprado ? Colors.grey.shade200 : Colors.white,
                        child: ListTile(
                          leading: Checkbox(
                            value: comprado,
                            activeColor: AppColors.primarySage,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (_) => _alternarStatusItem(item.id, comprado),
                          ),
                          title: Text(
                            item['nome'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: comprado ? Colors.grey.shade500 : AppColors.textDark,
                              decoration: comprado ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
