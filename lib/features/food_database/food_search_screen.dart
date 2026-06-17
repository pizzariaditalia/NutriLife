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

  // 🍎 BANCO DE DADOS LOCAL
  final List<Map<String, dynamic>> _bancoLocal = [
    {'nome': "Arroz Branco (cozido)", 'kcal100g': 130, 'medida_base': 'g/ml'},
    {'nome': "Arroz Integral (cozido)", 'kcal100g': 112, 'medida_base': 'g/ml'},
    {'nome': "Feijão Carioca (cozido)", 'kcal100g': 76, 'medida_base': 'g/ml'},
    {'nome': "Batata Doce (cozida)", 'kcal100g': 86, 'medida_base': 'g/ml'},
    {'nome': "Ovo de Galinha Cozido", 'kcal100g': 78, 'medida_base': 'Unidade(s)'},
    {'nome': "Peito de Frango (grelhado)", 'kcal100g': 165, 'medida_base': 'g/ml'},
    {'nome': "Banana Prata", 'kcal100g': 98, 'medida_base': 'Unidade(s)'},
    {'nome': "Pão Francês", 'kcal100g': 150, 'medida_base': 'Unidade(s)'},
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

  // 🚀 O MOTOR DE BUSCA GLOBAL (Local + Comunidade Firestore + API)
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
      String termoLimpo = _removerAcentos(query);
      
      // 1. Filtra no Banco Local
      List<Map<String, dynamic>> resultadosLocais = _bancoLocal.where((alimento) {
        return _removerAcentos(alimento['nome']).contains(termoLimpo);
      }).toList();

      setState(() {
        _resultadosBusca = resultadosLocais;
        _buscandoAPI = true;
      });

      // 2. Busca na Comunidade (Firestore) - Alimentos inseridos por outros pacientes!
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('alimentos_comunidade')
            .where('nome_busca', isGreaterThanOrEqualTo: termoLimpo)
            .where('nome_busca', isLessThanOrEqualTo: termoLimpo + '\uf8ff')
            .limit(10)
            .get();
        
        for (var doc in querySnap.docs) {
          final data = doc.data();
          resultadosLocais.add({
            'nome': "${data['nome']} (Comunidade 🤝)",
            'kcal100g': data['kcal100g'],
            'medida_base': data['medida_base'] ?? 'Unidade(s)'
          });
        }
      } catch (e) {
        debugPrint("Erro ao buscar na comunidade: $e");
      }

      // 3. Busca na API Global (OpenFoodFacts)
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
                  'medida_base': 'g/ml'
                });
              }
            }

            if (mounted) {
              setState(() {
                // Junta tudo evitando duplicatas
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

  // 📝 PONTO 3: MODAL PARA CADASTRAR ALIMENTO MANUALMENTE NA COMUNIDADE
  void _abrirModalCadastroManual() {
    final nomeCtrl = TextEditingController(text: _buscaController.text);
    final kcalCtrl = TextEditingController();
    String medidaBaseSelecionada = 'Unidade(s)';

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
                const Text('Cadastrar Novo Alimento 🌎', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Text('Esse alimento ficará salvo para você e para toda a comunidade!', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: 'Nome do Alimento', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: kcalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Calorias', suffixText: 'kcal', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: medidaBaseSelecionada,
                        decoration: InputDecoration(labelText: 'Medida', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                        items: ['100 g/ml', 'Unidade(s)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setStateModal(() => medidaBaseSelecionada = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      if (nomeCtrl.text.trim().isEmpty || kcalCtrl.text.trim().isEmpty) return;
                      int kcal = int.tryParse(kcalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      
                      final novoItem = {
                        'nome': nomeCtrl.text.trim(),
                        'nome_busca': _removerAcentos(nomeCtrl.text.trim()),
                        'kcal100g': kcal, // Nome interno mantido
                        'medida_base': medidaBaseSelecionada == '100 g/ml' ? 'g/ml' : 'Unidade(s)',
                      };

                      // Salva no banco global da comunidade!
                      await FirebaseFirestore.instance.collection('alimentos_comunidade').add({
                        ...novoItem,
                        'criado_por': _userId,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        Navigator.pop(context); // Fecha cadastro
                        _abrirModalQuantidade(novoItem); // Abre a calculadora já com ele pronto
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alimento partilhado com a comunidade! 🌟'), backgroundColor: AppColors.secondaryMenta));
                      }
                    },
                    child: const Text('Salvar e Usar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

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
            child: _resultadosBusca.isEmpty && !_buscandoAPI && _buscaController.text.isNotEmpty
                // 🚀 PONTO 3: TELA VAZIA CONVIDANDO A CRIAR O ALIMENTO
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Não encontrou o alimento?', style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Seja o primeiro a cadastrar esse item e ajude a nossa comunidade a crescer!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _abrirModalCadastroManual,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Cadastrar Manualmente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryMenta, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          )
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultadosBusca.length,
                    itemBuilder: (context, index) {
                      final item = _resultadosBusca[index];
                      String subtitulo = item['medida_base'] == 'Unidade(s)' 
                          ? '${item['kcal100g']} kcal por Unidade'
                          : '${item['kcal100g']} kcal a cada 100 g/ml';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                          subtitle: Text(subtitulo, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
// ⚖️ CALCULADORA EXATA COM OPÇÃO DE UNIDADES
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
  final TextEditingController _qtdController = TextEditingController(text: "1");
  late String _medidaSelecionada;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    // 🚀 PONTO 2: Define o dropdown com base no que veio do banco
    _medidaSelecionada = widget.alimento['medida_base'] ?? 'g/ml';
    if (_medidaSelecionada == 'g/ml') {
      _qtdController.text = "100"; // Padrão 100g
    } else {
      _qtdController.text = "1";   // Padrão 1 Unidade
    }
  }

  int _calcularCalorias() {
    double qtd = double.tryParse(_qtdController.text.replaceAll(',', '.')) ?? 0;
    int baseKcal = widget.alimento['kcal100g'] ?? 0;
    
    // 🚀 PONTO 2: A Matemática muda dependendo do que o usuário escolher!
    if (_medidaSelecionada == 'g/ml') {
      return ((baseKcal / 100) * qtd).round();
    } else {
      return (baseKcal * qtd).round(); // Se for unidade, multiplica direto
    }
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
        'quantidade': qtd,
        'medida_escolhida': _medidaSelecionada,
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
          Text('Base cadastrada: ${widget.alimento['kcal100g']} kcal', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('QUANTIDADE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qtdController,
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
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MEDIDA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    // 🚀 PONTO 2: SELETOR DE UNIDADE OU GRAMAS
                    DropdownButtonFormField<String>(
                      value: _medidaSelecionada,
                      decoration: InputDecoration(
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      items: ['g/ml', 'Unidade(s)'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _medidaSelecionada = val!;
                          if (_medidaSelecionada == 'g/ml') {
                            _qtdController.text = "100";
                          } else {
                            _qtdController.text = "1";
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL DE CALORIAS:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primarySage.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${_calcularCalorias()} kcal', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primarySage),
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
