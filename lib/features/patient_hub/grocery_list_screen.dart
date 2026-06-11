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
  
  // Lista local para guardar o que já foi colocado no carrinho
  final Set<String> _itensNoCarrinho = {};

  // Função mágica que pega os textos da dieta e transforma numa lista limpa
  List<String> _gerarListaDeCompras(Map<String, dynamic>? plano) {
    if (plano == null) return [];
    
    String textoCompleto = "";
    if (plano['cafe'] != null) textoCompleto += "${plano['cafe']}\n";
    if (plano['almoco'] != null) textoCompleto += "${plano['almoco']}\n";
    if (plano['lanche'] != null) textoCompleto += "${plano['lanche']}\n";
    if (plano['jantar'] != null) textoCompleto += "${plano['jantar']}\n";

    // Quebra o texto por linhas e remove linhas vazias ou textos inúteis
    List<String> linhas = textoCompleto.split('\n');
    List<String> itensLimpos = [];

    for (String linha in linhas) {
      String item = linha.replaceAll('•', '').trim();
      if (item.isNotEmpty && item.length > 3) {
        // Evita itens duplicados na lista do mercado
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
          
          List<String> listaDoMercado = _gerarListaDeCompras(planoAlimentar);

          if (listaDoMercado.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Sua lista está vazia!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text('Aguarde sua nutricionista enviar o plano alimentar. Nós vamos gerar sua lista de compras automaticamente aqui.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            );
          }

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
                    const Icon(Icons.auto_awesome, color: Colors.white70, size: 24),
                    const SizedBox(height: 8),
                    const Text('Gerada pela sua Dieta', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      itensPendentes == 0 ? 'Tudo no carrinho! 🎉' : 'Faltam $itensPendentes itens para comprar', 
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

              // LISTA DO SUPERMERCADO
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: listaDoMercado.length,
                  itemBuilder: (context, index) {
                    final item = listaDoMercado[index];
                    final noCarrinho = _itensNoCarrinho.contains(item);

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
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: noCarrinho ? FontWeight.normal : FontWeight.bold,
                            color: noCarrinho ? Colors.grey.shade500 : AppColors.textDark,
                            decoration: noCarrinho ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        secondary: Icon(
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
