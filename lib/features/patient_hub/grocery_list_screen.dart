import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({Key? key}) : super(key: key);

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final TextEditingController _novoItemCtrl = TextEditingController();
  
  // Lista local para guardar o que já foi colocado no carrinho
  final Set<String> _itensNoCarrinho = {};

  // Função mágica que pega os textos da dieta e transforma numa lista limpa
  List<String> _gerarListaDeComprasDaDieta(Map<String, dynamic>? plano) {
    if (plano == null) return [];
    
    String textoCompleto = "";
    if (plano['cafe'] != null) textoCompleto += "${plano['cafe']}\n";
    if (plano['almoco'] != null) textoCompleto += "${plano['almoco']}\n";
    if (plano['lanche'] != null) textoCompleto += "${plano['lanche']}\n";
    if (plano['jantar'] != null) textoCompleto += "${plano['jantar']}\n";

    List<String> linhas = textoCompleto.split('\n');
    List<String> itensLimpos = [];

    for (String linha in linhas) {
      String item = linha.replaceAll('•', '').trim();
      if (item.isNotEmpty && item.length > 3) {
        if (!itensLimpos.contains(item)) {
          itensLimpos.add(item);
        }
      }
    }
    return itensLimpos;
  }

  void _alternarCarrinho(String item) {
    setState(() {
      if (_itensNoCarrinho.contains(item)) {
        _itensNoCarrinho.remove(item);
      } else {
        _itensNoCarrinho.add(item);
      }
    });
  }

  // 🚀 PONTO 4: Salva item customizado no banco do paciente
  void _adicionarItemPessoal() async {
    if (_novoItemCtrl.text.trim().isEmpty) return;
    String novoItem = "🛒 " + _novoItemCtrl.text.trim(); // Emoji para diferenciar
    _novoItemCtrl.clear();
    FocusScope.of(context).unfocus();

    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set({
      'itens_mercado_extras': FieldValue.arrayUnion([novoItem])
    }, SetOptions(merge: true));
  }

  // 🚀 PONTO 4: Apaga item customizado
  void _removerItemPessoal(String item) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set({
      'itens_mercado_extras': FieldValue.arrayRemove([item])
    }, SetOptions(merge: true));
    
    if (_itensNoCarrinho.contains(item)) {
      setState(() => _itensNoCarrinho.remove(item));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Lista de Compras', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
          }

          final dadosUser = snapshot.data!.data() as Map<String, dynamic>?;
          final planoAlimentar = dadosUser?['plano_alimentar'] as Map<String, dynamic>?;
          
          // Pega os itens salvos manualmente pelo paciente
          final List<dynamic> itensExtras = dadosUser?['itens_mercado_extras'] ?? [];
          
          // Junta a dieta da Nutri com os itens extras do paciente
          List<String> listaDoMercado = [
            ..._gerarListaDeComprasDaDieta(planoAlimentar),
            ...itensExtras.map((e) => e.toString()),
          ];

          int itensPendentes = listaDoMercado.length - _itensNoCarrinho.length;

          return Column(
            children: [
              // HEADER INTELIGENTE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primarySage,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_cart_checkout, color: Colors.white70, size: 28),
                    const SizedBox(height: 8),
                    const Text('Sua Lista Inteligente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      listaDoMercado.isEmpty 
                        ? 'Adicione itens abaixo!' 
                        : (itensPendentes == 0 ? 'Tudo no carrinho! 🎉' : 'Faltam $itensPendentes itens para comprar'), 
                      style: const TextStyle(color: Colors.white70, fontSize: 14)
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: listaDoMercado.isNotEmpty ? (_itensNoCarrinho.length / listaDoMercado.length) : 0,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    )
                  ],
                ),
              ),

              // 🚀 PONTO 4: BARRA DE ADICIONAR ITEM EXTRA
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _novoItemCtrl,
                        decoration: InputDecoration(
                          hintText: 'Adicionar item extra...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _adicionarItemPessoal(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _adicionarItemPessoal,
                      backgroundColor: AppColors.secondaryMenta,
                      elevation: 0,
                      mini: true,
                      child: const Icon(Icons.add, color: Colors.white),
                    )
                  ],
                ),
              ),

              // LISTA DO SUPERMERCADO
              Expanded(
                child: listaDoMercado.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Lista vazia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: listaDoMercado.length,
                      itemBuilder: (context, index) {
                        final item = listaDoMercado[index];
                        final noCarrinho = _itensNoCarrinho.contains(item);
                        final isItemPessoal = item.startsWith('🛒');

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: noCarrinho ? Colors.grey.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: noCarrinho ? Colors.grey.shade200 : Colors.grey.shade300),
                          ),
                          child: CheckboxListTile(
                            value: noCarrinho,
                            onChanged: (bool? value) => _alternarCarrinho(item),
                            activeColor: AppColors.primarySage,
                            checkColor: Colors.white,
                            contentPadding: const EdgeInsets.only(left: 8, right: 0),
                            title: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: noCarrinho ? FontWeight.normal : FontWeight.bold,
                                color: noCarrinho ? Colors.grey.shade500 : AppColors.textDark,
                                decoration: noCarrinho ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                            secondary: isItemPessoal
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _removerItemPessoal(item),
                                  )
                                : Icon(
                                    noCarrinho ? Icons.check_circle : Icons.circle_outlined,
                                    color: noCarrinho ? AppColors.primarySage : Colors.grey.shade400,
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
