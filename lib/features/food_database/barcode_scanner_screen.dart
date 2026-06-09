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

  // 🌐 MOTOR ATUALIZADO: Busca na base mundial com conversores seguros
  Future<Map<String, dynamic>?> _consultarApiMundial(String codigo) async {
    // Usando o endpoint 'world' para garantir a localização de códigos globais (ex: Coca-Cola)
    final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$codigo.json');
    
    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        
        if (dados['status'] == 1 && dados['product'] != null) {
          final p = dados['product'];
          final nutrients = p['nutriments'] ?? {};

          // 🛡️ Extrator Seguro: Evita falhas caso a API envie texto no lugar de número
          double obterValorSeguro(String chave) {
            final valor = nutrients[chave];
            if (valor == null) return 0.0;
            if (valor is num) return valor.toDouble();
            if (valor is String) return double.tryParse(valor) ?? 0.0;
            return 0.0;
          }

          // Pegando os dados padrão da API (Geralmente 100g ou 100ml)
          final double kcal100g = obterValorSeguro('energy-kcal_100g');
          final double carbos100g = obterValorSeguro('carbohydrates_100g');
          final double proteinas100g = obterValorSeguro('proteins_100g');
          final double gorduras100g = obterValorSeguro('fat_100g');

          // Prioriza o nome em Português, se não achar, pega o nome global
          String nomeProduto = p['product_name_pt'] ?? p['product_name'] ?? 'Produto Detectado';
          String marcaProduto = p['brands']?.split(',').first ?? 'Marca Desconhecida';

          return {
            'nome': nomeProduto,
            'marca': marcaProduto,
            'kcal': kcal100g.toInt(),
            'carbos': carbos100g,
            'proteinas': proteinas100g,
            'gorduras': gorduras100g,
            'porcao': '100g/ml (Base API)'
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
      _jaEscaneou = true; // Trava o scanner para não ler várias vezes
    });

    // Faz a consulta na nuvem
    final produtoDetectado = await _consultarApiMundial(codigo);

    setState(() {
      _buscandoNaApi = false;
    });

    if (produtoDetectado != null) {
      // Se achou, abre o painel para o usuário ajustar a quantidade e confirmar
      _mostrarPainelDeConfirmacao(produtoDetectado);
    } else {
      // Se realmente não existir no banco de dados mundial
      _mostrarPainelDeConfirmacao({
        'nome': 'Item Código $codigo',
        'marca': 'Não encontrado na base global',
        'kcal': 0, 'carbos': 0.0, 'proteinas': 0.0, 'gorduras': 0.0, 'porcao': 'Personalizado'
      });
    }
  }

  // 📝 PAINEL DE EDIÇÃO: Igual ao MyFitnessPal, permite ajustar calorias reais consumidas
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
                      Navigator.pop(context); // Fecha o dialog
                      setState(() => _jaEscaneou = false); // Libera o scanner para tentar de novo
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
                    onPressed: () => _salvarNoDiario(produto, kcalController.text, porcaoController.text),
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

  // 💾 SALVA NO FIREBASE
  void _salvarNoDiario(Map<String, dynamic> produtoBase, String kcalDigitada, String multiplicadorDigitado) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    int kcalFinal = int.tryParse(kcalDigitada) ?? produtoBase['kcal'];
    double multiplicador = double.tryParse(multiplicadorDigitado.replaceAll(',', '.')) ?? 1.0;
    
    // Multiplica os macros pela quantidade que o usuário informou
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
          'nome': "📸 ${produtoBase['nome']} (${produtoBase['marca']})",
          'turno': widget.turno,
          'quantidade': multiplicador,
          'medida_escolhida': produtoBase['porcao'],
          'calorias': caloriasTotais,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context); // Fecha o bottom sheet
      Navigator.pop(context); // Fecha o leitor e volta pro diário
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
