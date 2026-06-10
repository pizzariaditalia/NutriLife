import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import 'barcode_scanner_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  final String turno;
  const FoodSearchScreen({Key? key, this.turno = 'Geral'}) : super(key: key);

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _buscaController = TextEditingController();
  Timer? _debounce;
  bool _buscandoNaNuvem = false;

  List<Map<String, dynamic>> _resultados = [
    {'nome': 'Arroz Branco Cozido', 'marca': 'Caseiro', 'kcal': 130, 'carbos': 28.0, 'proteinas': 2.0, 'gorduras': 0.0, 'porcao': '100g'},
    {'nome': 'Feijão Carioca Cozido', 'marca': 'Caseiro', 'kcal': 76, 'carbos': 14.0, 'proteinas': 4.0, 'gorduras': 0.0, 'porcao': '100g'},
    {'nome': 'Peito de Frango Grelhado', 'marca': 'Caseiro', 'kcal': 165, 'carbos': 0.0, 'proteinas': 31.0, 'gorduras': 3.0, 'porcao': '100g'},
    {'nome': 'Ovo Cozido', 'marca': 'Granja', 'kcal': 78, 'carbos': 0.0, 'proteinas': 6.0, 'gorduras': 5.0, 'porcao': '1 Unidade (50g)'},
    {'nome': 'Banana Prata', 'marca': 'In Natura', 'kcal': 89, 'carbos': 23.0, 'proteinas': 1.0, 'gorduras': 0.0, 'porcao': '1 Unidade (100g)'},
    {'nome': 'Carne Moída Patinho Grelhado', 'marca': 'Açougue', 'kcal': 219, 'carbos': 0.0, 'proteinas': 32.0, 'gorduras': 9.0, 'porcao': '100g'},
    {'nome': 'Batata Doce Cozida', 'marca': 'In Natura', 'kcal': 86, 'carbos': 20.0, 'proteinas': 1.6, 'gorduras': 0.0, 'porcao': '100g'},
    {'nome': 'Whey Protein 80%', 'marca': 'Growth/Max', 'kcal': 120, 'carbos': 4.0, 'proteinas': 24.0, 'gorduras': 1.0, 'porcao': '1 Dosador (30g)'},
    {'nome': 'Aveia em Flocos', 'marca': 'Quaker', 'kcal': 105, 'carbos': 17.0, 'proteinas': 4.3, 'gorduras': 2.2, 'porcao': '2 colheres (30g)'},
    {'nome': 'Tapioca Pronta', 'marca': 'Akio', 'kcal': 240, 'carbos': 60.0, 'proteinas': 0.0, 'gorduras': 0.0, 'porcao': '100g'},
    {'nome': 'Iogurte Natural Desnatado', 'marca': 'Nestlé', 'kcal': 52, 'carbos': 7.0, 'proteinas': 5.0, 'gorduras': 0.0, 'porcao': '1 Pote (170g)'},
    {'nome': 'Pão de Forma Integral', 'marca': 'Wickbold', 'kcal': 120, 'carbos': 22.0, 'proteinas': 6.0, 'gorduras': 1.5, 'porcao': '2 Fatias (50g)'},
    {'nome': 'Pasta de Amendoim', 'marca': 'IntegralMedica', 'kcal': 90, 'carbos': 3.0, 'proteinas': 4.0, 'gorduras': 8.0, 'porcao': '1 Colher (15g)'},
    {'nome': 'Azeite de Oliva Extra Virgem', 'marca': 'Galo', 'kcal': 120, 'carbos': 0.0, 'proteinas': 0.0, 'gorduras': 14.0, 'porcao': '1 Colher (13ml)'},
    {'nome': 'Queijo Cottage', 'marca': 'Verde Campo', 'kcal': 90, 'carbos': 3.0, 'proteinas': 12.0, 'gorduras': 3.0, 'porcao': '2 colheres (50g)'},
    {'nome': 'Maçã Fuji', 'marca': 'In Natura', 'kcal': 52, 'carbos': 14.0, 'proteinas': 0.3, 'gorduras': 0.2, 'porcao': '1 Unidade (100g)'},
    {'nome': 'Castanha do Pará', 'marca': 'Granel', 'kcal': 65, 'carbos': 1.2, 'proteinas': 1.4, 'gorduras': 6.5, 'porcao': '2 Unidades (10g)'},
    {'nome': 'Cuscuz de Milho Cozido', 'marca': 'Flokin', 'kcal': 112, 'carbos': 25.0, 'proteinas': 2.2, 'gorduras': 0.5, 'porcao': '100g'},
    {'nome': 'Leite Desnatado líquido', 'marca': 'Molico', 'kcal': 70, 'carbos': 10.0, 'proteinas': 6.5, 'gorduras': 0.0, 'porcao': '1 Copo (200ml)'},
    {'nome': 'Atum Ralado em Óleo', 'marca': 'Coqueiro', 'kcal': 160, 'carbos': 0.0, 'proteinas': 24.0, 'gorduras': 7.0, 'porcao': '1 Lata (120g)'},
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  void _pesquisarAlimento(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (query.trim().isEmpty) {
        setState(() => _buscandoNaNuvem = false);
        return; 
      }

      setState(() => _buscandoNaNuvem = true);

      try {
        final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=15');
        final resposta = await http.get(url);

        if (resposta.statusCode == 200) {
          final dados = jsonDecode(resposta.body);
          final produtosExtraidos = dados['products'] as List;

          List<Map<String, dynamic>> novosResultados = [];

          for (var p in produtosExtraidos) {
            final nutrients = p['nutriments'] ?? {};

            double obterValorSeguro(String chave) {
              final valor = nutrients[chave];
              if (valor == null) return 0.0;
              if (valor is num) return valor.toDouble();
              if (valor is String) return double.tryParse(valor) ?? 0.0;
              return 0.0;
            }

            final double kcal = obterValorSeguro('energy-kcal_100g');
            if (kcal > 0) {
              novosResultados.add({
                'nome': p['product_name_pt'] ?? p['product_name'] ?? 'Produto',
                'marca': p['brands']?.split(',').first ?? 'Industrializado',
                'kcal': kcal.toInt(),
                'carbos': obterValorSeguro('carbohydrates_100g'),
                'proteinas': obterValorSeguro('proteins_100g'),
                'gorduras': obterValorSeguro('fat_100g'),
                'porcao': '100g/ml (Base API)',
              });
            }
          }

          if (mounted) {
            setState(() {
              _resultados = novosResultados;
              _buscandoNaNuvem = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Erro na busca: $e');
        if (mounted) setState(() => _buscandoNaNuvem = false);
      }
    });
  }

  void _mostrarPainelDeConfirmacao(Map<String, dynamic> produto) {
    TextEditingController kcalController = TextEditingController(text: produto['kcal'].toString());
    TextEditingController porcaoController = TextEditingController(text: '1.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 24, right: 24
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirmar Alimento 🔍', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            // 🚀 CORRIGIDO: de grandmother para fontWeight
            Text('${produto['nome']} - ${produto['marca']}', style: const TextStyle(fontSize: 16, color: AppColors.primarySage, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Valores baseados em: ${produto['porcao']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: kcalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Calorias (kcal)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: porcaoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Multiplicador', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey)))),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => _salvarNoDiario(produto, kcalController.text, porcaoController.text),
                    // 🚀 CORRIGIDO: de grandmother para fontWeight
                    child: const Text('Salvar Diário', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _salvarNoDiario(Map<String, dynamic> produtoBase, String kcalDigitada, String multiplicadorDigitado) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    int kcalFinal = int.tryParse(kcalDigitada) ?? produtoBase['kcal'];
    double multiplicador = double.tryParse(multiplicadorDigitado.replaceAll(',', '.')) ?? 1.0;
    
    int caloriasTotais = (kcalFinal * multiplicador).toInt();
    double carbosTotais = produtoBase['carbos'] * multiplicador;
    double proteinasTotais = produtoBase['proteinas'] * multiplicador;
    double gordurasTotais = produtoBase['gorduras'] * multiplicador;

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataHoje);

    await docRef.set({
      'calorias_consumidas': FieldValue.increment(caloriasTotais),
      'carbos_consumidos': FieldValue.increment(carbosTotais),
      'proteinas_consumidos': FieldValue.increment(proteinasTotais),
      'gorduras_consumidos': FieldValue.increment(gordurasTotais),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': "${produtoBase['nome']} (${produtoBase['marca']})",
          'turno': widget.turno,
          'quantidade': multiplicador,
          'medida_escolhida': produtoBase['porcao'],
          'calorias': caloriasTotais,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚡ Adicionado ao ${widget.turno}!'), backgroundColor: AppColors.primarySage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: Text(widget.turno == 'Geral' ? 'Busca Global' : 'Adicionar ao ${widget.turno}', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primarySage,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscaController,
                    onChanged: _pesquisarAlimento,
                    decoration: InputDecoration(
                      hintText: 'Buscar alimento (ex: Danone)...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodeScannerScreen(turno: widget.turno))),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.qr_code_scanner, color: AppColors.primarySage),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _buscandoNaNuvem
                ? const Center(child: CircularProgressIndicator(color: AppColors.primarySage))
                : _resultados.isEmpty
                    ? Center(child: Text('Nenhum alimento encontrado.', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _resultados.length,
                        itemBuilder: (context, index) {
                          final item = _resultados[index];
                          return GestureDetector(
                            onTap: () => _mostrarPainelDeConfirmacao(item),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('${item['marca']} • ${item['porcao']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        const SizedBox(height: 8),
                                        // 🚀 CORRIGIDO: de grandmother para fontWeight
                                        Text('C: ${item['carbos'].toInt()}g  |  P: ${item['proteinas'].toInt()}g  |  G: ${item['gorduras'].toInt()}g', style: const TextStyle(fontSize: 11, color: AppColors.primarySage, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${item['kcal']} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentPeach)),
                                      const SizedBox(height: 8),
                                      const Icon(Icons.add_circle, color: AppColors.primarySage, size: 28),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
