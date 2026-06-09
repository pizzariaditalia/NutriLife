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
  final TextEditingController _itemController = TextEditingController();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  void _adicionarItem() async {
    if (_itemController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('lista_compras')
        .add({
      'nome': _itemController.text.trim(),
      'comprado': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _itemController.clear();
  }

  void _alternarStatus(String docId, bool statusAtual) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('lista_compras')
        .doc(docId)
        .update({'comprado': !statusAtual});
  }

  void _deletarItem(String docId) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('lista_compras')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Lista de Compras', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // BARRA DE ADICIONAR
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primarySage,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Adicionar produto (ex: Aveia)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _adicionarItem(),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _adicionarItem,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_shopping_cart, color: AppColors.primarySage),
                  ),
                )
              ],
            ),
          ),

          // LISTA DO FIREBASE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(_userId)
                  .collection('lista_compras')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Sua lista está vazia', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final dados = doc.data() as Map<String, dynamic>;
                    final bool comprado = dados['comprado'] ?? false;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: Checkbox(
                          value: comprado,
                          activeColor: AppColors.primarySage,
                          onChanged: (_) => _alternarStatus(doc.id, comprado),
                        ),
                        title: Text(
                          dados['nome'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: comprado ? Colors.grey : AppColors.textDark,
                            decoration: comprado ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deletarItem(doc.id),
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
