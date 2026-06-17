import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String turno;
  const BarcodeScannerScreen({Key? key, required this.turno}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _jaEscaneou = false;
  bool _buscandoNaApi = false;

  Future<Map<String, dynamic>?> _consultarApiMundial(String codigo) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$codigo.json');
    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        if (dados['status'] == 1 && dados['product'] != null) {
          final p = dados['product'];
          final nutrients = p['nutriments'] ?? {};

          double obterValorSeguro(String chave) {
            final valor = nutrients[chave];
            if (valor == null) return 0.0;
            if (valor is num) return valor.toDouble();
            if (valor is String) return double.tryParse(valor) ?? 0.0;
            return 0.0;
          }

          final double kcal100g = obterValorSeguro('energy-kcal_100g');
          String nomeProduto = p['product_name_pt'] ?? p['product_name'] ?? 'Produto Detectado';
          String marcaProduto = p['brands']?.split(',').first ?? '';
          
          String nomeCompleto = marcaProduto.isNotEmpty ? "$nomeProduto ($marcaProduto)" : nomeProduto;

          return {
            'codigo_barras': codigo,
            'nome': nomeCompleto,
            'kcal': kcal100g.toInt(),
            'porcao': '100 g/ml'
          };
        }
      }
    } catch (e) {
      debugPrint('Erro na extração de dados da API: $e');
    }
    return null;
  }

  void _processarCodigoDetectado(String codigo) async {
    if (_jaEscaneou || _buscandoNaApi) return;
    
    setState(() {
      _buscandoNaApi = true;
      _jaEscaneou = true;
    });

    final produtoDetectado = await _consultarApiMundial(codigo);

    setState(() {
      _buscandoNaApi = false;
    });

    if (produtoDetectado != null) {
      _mostrarPainelDeConfirmacao(produtoDetectado);
    } else {
      _mostrarPainelDeConfirmacao({
        'codigo_barras': codigo,
        'nome': 'Item Código $codigo',
        'kcal': 0, 
        'porcao': 'Personalizado'
      });
    }
  }

  void _mostrarPainelDeConfirmacao(Map<String, dynamic> produto) {
    TextEditingController kcalController = TextEditingController(text: produto['kcal'].toString());
    TextEditingController porcaoController = TextEditingController(text: '1.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
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
            Text('${produto['nome']}', style: const TextStyle(fontSize: 16, color: AppColors.primarySage, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Valores baseados em: ${produto['porcao']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: kcalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total de Calorias (kcal)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primarySage)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: porcaoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Multiplicador (Qtd)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primarySage)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _jaEscaneou = false);
                    },
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySage,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => _salvarNoDiarioEComunidade(produto, kcalController.text, porcaoController.text),
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

  // 🚀 PONTO 3: SALVA NO DIÁRIO E NA COMUNIDADE AO MESMO TEMPO
  void _salvarNoDiarioEComunidade(Map<String, dynamic> produtoBase, String kcalDigitada, String multiplicadorDigitado) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    int kcalFinal = int.tryParse(kcalDigitada) ?? produtoBase['kcal'];
    double multiplicador = double.tryParse(multiplicadorDigitado.replaceAll(',', '.')) ?? 1.0;
    
    int caloriasTotais = (kcalFinal * multiplicador).toInt();

    // 1. Salva no diário do paciente
    final docRefDiario = FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataHoje);

    await docRefDiario.set({
      'calorias_consumidas': FieldValue.increment(caloriasTotais),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': "📸 ${produtoBase['nome']}",
          'turno': widget.turno,
          'quantidade': multiplicador,
          'medida_escolhida': produtoBase['porcao'],
          'calorias': caloriasTotais,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    // 2. Salva no banco orgânico da comunidade (usando o código de barras como ID para não duplicar)
    if (produtoBase['codigo_barras'] != null && produtoBase['nome'] != null && !produtoBase['nome'].toString().startsWith('Item Código')) {
      final String nomeBuscaLimpo = produtoBase['nome'].toString().toLowerCase()
          .replaceAll(RegExp(r'[áàâãä]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòôõö]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u')
          .replaceAll('ç', 'c');

      await FirebaseFirestore.instance.collection('alimentos_comunidade').doc(produtoBase['codigo_barras']).set({
        'nome': produtoBase['nome'],
        'nome_busca': nomeBuscaLimpo,
        'kcal100g': kcalFinal,
        'medida_base': 'g/ml',
        'criado_por': 'api_scanner',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚡ ${produtoBase['nome']} salvo com sucesso!'), backgroundColor: AppColors.primarySage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Produto', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (!_buscandoNaApi)
            MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processarCodigoDetectado(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),

          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(color: Colors.transparent),
                Center(
                  child: Container(
                    width: 280, height: 200,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 280, height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondaryMenta, width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          if (_buscandoNaApi)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AppColors.secondaryMenta),
                    SizedBox(height: 16),
                    Text('Lendo tabela nutricional...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
