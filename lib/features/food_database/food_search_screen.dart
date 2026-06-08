import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import 'barcode_scanner_screen.dart';

class Alimento {
  final String nome;
  final String porcaoBase;
  final int calorias;
  final double carbos;
  final double proteinas;
  final double gorduras;
  final bool isProcessado;
  final String alertaProcessado;
  final List<String> medidasCaseiras;

  Alimento({
    required this.nome,
    required this.porcaoBase,
    required this.calorias,
    required this.carbos,
    required this.proteinas,
    required this.gorduras,
    this.isProcessado = false,
    this.alertaProcessado = '',
    required this.medidasCaseiras,
  });
}

class FoodSearchScreen extends StatefulWidget {
  final String turno;
  const FoodSearchScreen({Key? key, this.turno = 'Lanche'}) : super(key: key);

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // 📚 BASE DE DADOS EXPANDIDA EM MASSA (PADRÃO PREMIUM TACO)
  final List<Alimento> _bancoDeAlimentos = [
    Alimento(nome: 'Arroz Branco Cozido', porcaoBase: '100g', calorias: 130, carbos: 28.0, proteinas: 2.5, gorduras: 0.2, medidasCaseiras: ['1 Colher de sopa (25g)', '1 Escumadeira (100g)']),
    Alimento(nome: 'Arroz Integral Cozido', porcaoBase: '100g', calorias: 124, carbos: 25.8, proteinas: 2.6, gorduras: 1.0, medidasCaseiras: ['1 Colher de sopa (25g)', '1 Escumadeira (100g)']),
    Alimento(nome: 'Feijão Carioca Cozido', porcaoBase: '100g', calorias: 76, carbos: 14.0, proteinas: 4.8, gorduras: 0.5, medidasCaseiras: ['1 Concha média (100g)']),
    Alimento(nome: 'Feijão Preto Cozido', porcaoBase: '100g', calorias: 77, carbos: 14.0, proteinas: 4.5, gorduras: 0.5, medidasCaseiras: ['1 Concha média (100g)']),
    Alimento(nome: 'Peito de Frango Grelhado', porcaoBase: '100g', calorias: 165, carbos: 0.0, proteinas: 31.5, gorduras: 3.6, medidasCaseiras: ['1 Filé médio (100g)', '1 Filé grande (150g)']),
    Alimento(nome: 'Patinho Moído Grelhado', porcaoBase: '100g', calorias: 219, carbos: 0.0, proteinas: 35.9, gorduras: 7.3, medidasCaseiras: ['3 Colheres de sopa (100g)']),
    Alimento(nome: 'Ovo Cozido', porcaoBase: '50g', calorias: 78, carbos: 0.6, proteinas: 6.3, gorduras: 5.3, medidasCaseiras: ['1 Unidade inteira']),
    Alimento(nome: 'Ovo Frito', porcaoBase: '50g', calorias: 120, carbos: 0.6, proteinas: 6.3, gorduras: 10.1, medidasCaseiras: ['1 Unidade inteira']),
    Alimento(nome: 'Pão Francês', porcaoBase: '50g', calorias: 150, carbos: 29.0, proteinas: 4.7, gorduras: 1.5, medidasCaseiras: ['1 Unidade (50g)']),
    Alimento(nome: 'Pão de Forma Integral', porcaoBase: '50g', calorias: 110, carbos: 22.0, proteinas: 4.5, gorduras: 1.1, medidasCaseiras: ['2 Fatias (50g)']),
    Alimento(nome: 'Tapioca (Goma Pronta)', porcaoBase: '50g', calorias: 120, carbos: 27.0, proteinas: 0.0, gorduras: 0.0, medidasCaseiras: ['3 Colheres de sopa (50g)']),
    Alimento(nome: 'Cuscuz de Milho', porcaoBase: '100g', calorias: 112, carbos: 25.0, proteinas: 2.2, gorduras: 0.6, medidasCaseiras: ['1 Pedaço médio (100g)']),
    Alimento(nome: 'Banana Prata', porcaoBase: '100g', calorias: 89, carbos: 23.0, proteinas: 1.3, gorduras: 0.3, medidasCaseiras: ['1 Unidade média']),
    Alimento(nome: 'Maçã Fuji', porcaoBase: '100g', calorias: 56, carbos: 15.0, proteinas: 0.3, gorduras: 0.2, medidasCaseiras: ['1 Unidade pequena']),
    Alimento(nome: 'Mamão Papaia', porcaoBase: '100g', calorias: 46, carbos: 11.6, proteinas: 0.5, gorduras: 0.1, medidasCaseiras: ['Metade de uma unidade']),
    Alimento(nome: 'Leite Integral Fluidificado', porcaoBase: '200ml', calorias: 120, carbos: 10.0, proteinas: 6.0, gorduras: 6.7, medidasCaseiras: ['1 Copo americano']),
    Alimento(nome: 'Leite Desnatado Fluidificado', porcaoBase: '200ml', calorias: 70, carbos: 10.0, proteinas: 6.0, gorduras: 0.0, medidasCaseiras: ['1 Copo americano']),
    Alimento(nome: 'Queijo Muçarela', porcaoBase: '30g', calorias: 96, carbos: 0.9, proteinas: 7.0, gorduras: 7.3, medidasCaseiras: ['1 Fatia fina']),
    Alimento(nome: 'Queijo Minas Frescal', porcaoBase: '30g', calorias: 68, carbos: 1.0, proteinas: 5.2, gorduras: 5.0, medidasCaseiras: ['1 Fatia média']),
    Alimento(nome: 'Aveia em Flocos', porcaoBase: '30g', calorias: 112, carbos: 17.0, proteinas: 4.3, gorduras: 2.2, medidasCaseiras: ['2 Colheres de sopa']),
    Alimento(nome: 'Whey Protein Concentrado', porcaoBase: '30g', calorias: 120, carbos: 3.0, proteinas: 24.0, gorduras: 2.0, medidasCaseiras: ['1 Dosador cheio']),
    Alimento(nome: 'Pasta de Amendoim', porcaoBase: '15g', calorias: 90, carbos: 3.2, proteinas: 3.7, gorduras: 7.4, medidasCaseiras: ['1 Colher de sopa']),
    Alimento(nome: 'Biscoito Recheado Chocolate', porcaoBase: '30g', calorias: 145, carbos: 21.0, proteinas: 1.8, gorduras: 6.0, isProcessado: true, alertaProcessado: 'Açúcares refinados e gordura hidrogenada.', medidasCaseiras: ['3 Unidades']),
  ];

  List<Alimento> _resultados = [];

  @override
  void initState() {
    super.initState();
    _resultados = _bancoDeAlimentos;
  }

  void _filtrarAlimentos(String query) {
    setState(() {
      if (query.isEmpty) {
        _resultados = _bancoDeAlimentos;
      } else {
        _resultados = _bancoDeAlimentos.where((a) => a.nome.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _abrirSeletorDePorcao(Alimento alimento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConstruirBottomSheetPorcao(alimento: alimento, turno: widget.turno),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: Text('Adicionar ao ${widget.turno}'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primarySage,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filtrarAlimentos,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Buscar alimento...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primarySage),
                      filled: true,
                      fillColor: AppColors.backgroundCreme,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(color: AppColors.backgroundCreme, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primarySage),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BarcodeScannerScreen(turno: widget.turno)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _resultados.isEmpty
                ? const Center(child: Text('Nenhum alimento encontrado.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultados.length,
                    itemBuilder: (context, index) {
                      final alimento = _resultados[index];
                      return _CardAlimentoPremium(alimento: alimento, onTap: () => _abrirSeletorDePorcao(alimento));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CardAlimentoPremium extends StatelessWidget {
  final Alimento alimento;
  final VoidCallback onTap;
  const _CardAlimentoPremium({required this.alimento, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(alimento.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                  Text('${alimento.calorias} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primarySage)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Base: ${alimento.porcaoBase}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('C: ${alimento.carbos.toInt()}g', style: const TextStyle(color: AppColors.secondaryMenta, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('P: ${alimento.proteinas.toInt()}g', style: const TextStyle(color: AppColors.primarySage, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('G: ${alimento.gorduras.toInt()}g', style: const TextStyle(color: AppColors.accentPeach, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              if (alimento.isProcessado) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.accentPeach.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.accentPeach),
                      const SizedBox(width: 6),
                      Expanded(child: Text(alimento.alertaProcessado, style: const TextStyle(fontSize: 11, color: AppColors.accentPeach, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstruirBottomSheetPorcao extends StatefulWidget {
  final Alimento alimento;
  final String turno;
  const _ConstruirBottomSheetPorcao({required this.alimento, required this.turno});

  @override
  State<_ConstruirBottomSheetPorcao> createState() => _ConstruirBottomSheetPorcaoState();
}

class _ConstruirBottomSheetPorcaoState extends State<_ConstruirBottomSheetPorcao> {
  String? _medidaSelecionada;
  double _quantidade = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.alimento.medidasCaseiras.isNotEmpty) {
      _medidaSelecionada = widget.alimento.medidasCaseiras.first;
    }
  }

  void _salvarNoDiario() async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    double fator = _quantidade;
    int kcalCalculadas = (widget.alimento.calorias * fator).round();
    double carbosCalculados = widget.alimento.carbos * fator;
    double proteinasCalculadas = widget.alimento.proteinas * fator;
    double gordurasCalculadas = widget.alimento.gorduras * fator;

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataHoje);

    await docRef.set({
      'calorias_consumidas': FieldValue.increment(kcalCalculadas),
      'carbos_consumidos': FieldValue.increment(carbosCalculados),
      'proteinas_consumidos': FieldValue.increment(proteinasCalculadas),
      'gorduras_consumidos': FieldValue.increment(gordurasCalculadas),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': widget.alimento.nome,
          'turno': widget.turno,
          'quantidade': _quantidade,
          'medida_escolhida': _medidaSelecionada,
          'calorias': kcalCalculadas,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.alimento.nome} somado aos macros do dia!'), backgroundColor: AppColors.primarySage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(color: AppColors.backgroundCreme, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            Text(widget.alimento.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primarySage), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const Text('Multiplicador de Porção:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () { if (_quantidade > 0.5) { setState(() => _quantidade -= 0.5); } }, icon: const Icon(Icons.remove_circle_outline, size: 32, color: AppColors.primarySage)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_quantidade.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                IconButton(onPressed: () { setState(() => _quantidade += 0.5); }, icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primarySage)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Medida de Referência:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _medidaSelecionada,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primarySage),
                  items: widget.alimento.medidasCaseiras.map((String medida) {
                    return DropdownMenuItem<String>(value: medida, child: Text(medida, style: const TextStyle(color: AppColors.textDark)));
                  }).toList(),
                  onChanged: (String? novaMedida) { setState(() => _medidaSelecionada = novaMedida); },
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvarNoDiario,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Adicionar ao Diário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.backgroundCreme)),
            ),
          ],
        ),
      ),
    );
  }
}
