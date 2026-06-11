import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class FoodSearchScreen extends StatefulWidget {
  final String turno;
  const FoodSearchScreen({Key? key, required this.turno}) : super(key: key);

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final TextEditingController _buscaController = TextEditingController();
  
  List<Map<String, dynamic>> _resultadosBusca = [];
  bool _buscandoAPI = false;
  Timer? _debounce;

  // 🍎 BANCO DE DADOS LOCAL (Igual ao da Nutri para buscas ultrarrápidas)
  final List<Map<String, dynamic>> _bancoLocal = [
    {'nome': "Arroz Branco (cozido)", 'kcal100g': 130},
    {'nome': "Arroz Integral (cozido)", 'kcal100g': 112},
    {'nome': "Feijão Carioca (cozido)", 'kcal100g': 76},
    {'nome': "Batata Doce (cozida)", 'kcal100g': 86},
    {'nome': "Aveia em Flocos", 'kcal100g': 394},
    {'nome': "Tapioca (goma hidratada)", 'kcal100g': 240},
    {'nome': "Pão Francês", 'kcal100g': 300},
    {'nome': "Peito de Frango (grelhado)", 'kcal100g': 165},
    {'nome': "Patinho Moído (refogado)", 'kcal100g': 133},
    {'nome': "Filé de Tilápia / Salmão", 'kcal100g': 200},
    {'nome': "Ovo de Galinha Cozido", 'kcal100g': 155},
    {'nome': "Ovo Mexido (com fio de óleo)", 'kcal100g': 190},
    {'nome': "Leite Integral (líquido)", 'kcal100g': 62},
    {'nome': "Queijo Mussarela", 'kcal100g': 300},
    {'nome': "Whey Protein Concentrado (Pó)", 'kcal100g': 400},
    {'nome': "Banana Prata", 'kcal100g': 98},
    {'nome': "Maçã", 'kcal100g': 52},
    {'nome': "Morango", 'kcal100g': 32},
    {'nome': "Alface", 'kcal100g': 15},
    {'nome': "Tomate", 'kcal100g': 18},
    {'nome': "Azeite de Oliva Extra Virgem", 'kcal100g': 884},
    {'nome': "Pasta de Amendoim (Integral)", 'kcal100g': 588},
  ];

  @override
  void initState() {
    super.initState();
    _resultadosBusca = List.from(_bancoLocal);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  // 🚀 O MOTOR DE BUSCA GLOBAL (Local + API)
  void _pesquisar(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _resultadosBusca = List.from(_bancoLocal);
        _buscandoAPI = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      // 1. Filtra no Banco Local primeiro (Ignora acentos e maiúsculas)
      String termoLimpo = _removerAcentos(query);
      List<Map<String, dynamic>> resultadosLocais = _bancoLocal.where((alimento) {
        return _removerAcentos(alimento['nome']).contains(termoLimpo);
      }).toList();

      setState(() {
        _resultadosBusca = resultadosLocais;
        _buscandoAPI = true;
      });

      // 2. Busca na API Global (OpenFoodFacts)
      try {
        final url = Uri.parse('https://br.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=15');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['products'] != null) {
            List<Map<String, dynamic>> resultadosAPI = [];
            
            for (var p in data['products']) {
              if (p['product_name'] != null && p['nutriments'] != null && p['nutriments']['energy-kcal_100g'] != null) {
                double kcal = (p['nutriments']['energy-kcal_100g'] as num).toDouble();
                String marca = p['brands'] != null ? " (${p['brands'].split(',')[0]})" : "";
                resultadosAPI.add({
                  'nome': "${p['product_name']}$marca",
                  'kcal100g': kcal.round(),
                });
              }
            }

            if (mounted) {
              setState(() {
                // Junta os locais com a API, evitando duplicatas com nomes iguais
                List<Map<String, dynamic>> combinada = [...resultadosLocais, ...resultadosAPI];
                var nomesVistos = <String>{};
                _resultadosBusca = combinada.where((item) => nomesVistos.add(item['nome'])).toList();
                _buscandoAPI = false;
              });
            }
          }
        }
      } catch (e) {
        if (mounted) setState(() => _buscandoAPI = false);
        debugPrint("Erro na API: $e");
      }
    });
  }

  String _removerAcentos(String str) {
    var comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var semAcento = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsyYyZz';
    for (int i = 0; i < comAcento.length; i++) {
      str = str.replaceAll(comAcento[i], semAcento[i]);
    }
    return str.toLowerCase();
  }

  // 📝 ABRIR O MODAL PARA DIGITAR A QUANTIDADE EXATA (COM DECIMAIS)
  void _abrirModalQuantidade(Map<String, dynamic> alimento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CalculadoraPorcao(
        alimento: alimento,
        turno: widget.turno,
        userId: _userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: Text('Adicionar ao ${widget.turno}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primarySage,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: TextField(
              controller: _buscaController,
              onChanged: _pesquisar,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Ex: Batata Doce, Whey...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _buscandoAPI 
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ) 
                    : (_buscaController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _buscaController.clear();
                              _pesquisar("");
                            },
                          )
                        : null),
                filled: true,
                fillColor: Colors.black.withOpacity(0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          // RESULTADOS DA BUSCA
          Expanded(
            child: _resultadosBusca.isEmpty && !_buscandoAPI
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Nenhum alimento encontrado', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultadosBusca.length,
                    itemBuilder: (context, index) {
                      final item = _resultadosBusca[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                          subtitle: Text('${item['kcal100g']} kcal a cada 100g/ml', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          trailing: Container(
                            decoration: BoxDecoration(color: AppColors.primarySage.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: AppColors.primarySage),
                              onPressed: () => _abrirModalQuantidade(item),
                            ),
                          ),
                          onTap: () => _abrirModalQuantidade(item),
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

// ==========================================
// ⚖️ CALCULADORA EXATA DE PORÇÃO (MODAL)
// ==========================================
class _CalculadoraPorcao extends StatefulWidget {
  final Map<String, dynamic> alimento;
  final String turno;
  final String userId;
  
  const _CalculadoraPorcao({Key? key, required this.alimento, required this.turno, required this.userId}) : super(key: key);

  @override
  State<_CalculadoraPorcao> createState() => _CalculadoraPorcaoState();
}

class _CalculadoraPorcaoState extends State<_CalculadoraPorcao> {
  final TextEditingController _qtdController = TextEditingController(text: "100");
  bool _salvando = false;

  int _calcularCalorias() {
    double qtd = double.tryParse(_qtdController.text.replaceAll(',', '.')) ?? 0;
    int kcal100g = widget.alimento['kcal100g'] ?? 0;
    return ((kcal100g / 100) * qtd).round();
  }

  void _salvarNoDiario() async {
    double qtd = double.tryParse(_qtdController.text.replaceAll(',', '.')) ?? 0;
    if (qtd <= 0) return;

    setState(() => _salvando = true);

    try {
      final agora = DateTime.now();
      String dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
      int caloriasTotais = _calcularCalorias();

      final novoAlimento = {
        'nome': widget.alimento['nome'],
        'quantidade': qtd, // 🚀 Salva exatamente com os decimais!
        'medida_escolhida': 'g/ml',
        'calorias': caloriasTotais,
        'turno': widget.turno,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).collection('diario').doc(dataHoje);

      await docRef.set({
        'historico_alimentos': FieldValue.arrayUnion([novoAlimento]),
        'calorias_consumidas': FieldValue.increment(caloriasTotais),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        Navigator.pop(context); // Fecha a tela de busca e volta pro diário
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${widget.alimento['nome']} adicionado!'), backgroundColor: AppColors.primarySage));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar alimento.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.alimento['nome'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('Base: ${widget.alimento['kcal100g']} kcal a cada 100g/ml', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QUANTIDADE (g/ml)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qtdController,
                      // 🚀 AQUI É A MÁGICA: Permite digitar decimais como 15.5 ou 150.2
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CALORIAS TOTAIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: AppColors.primarySage.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primarySage.withOpacity(0.3))),
                      child: Text(
                        '${_calcularCalorias()} kcal', 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primarySage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvarNoDiario,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _salvando 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Adicionar ao Diário', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
