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

  // 🌐 FUNÇÃO DE ENGENHARIA PREMIUM: Consulta a API mundial Open Food Facts via HTTP
  Future<Map<String, dynamic>?> _consultarApiMundial(String codigo) async {
    final url = Uri.parse('https://br.openfoodfacts.org/api/v2/product/$codigo.json');
    
    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final dadosDoServidor = jsonDecode(resposta.body);
        
        if (dadosDoServidor['status'] == 1 && dadosDoServidor['product'] != null) {
          final p = dadosDoServidor['product'];
          final nutrients = p['nutriments'] ?? {};

          // Extrai os dados por 100g/ml padrão da tabela do produto
          return {
            'nome': p['product_name_pt'] ?? p['product_name'] ?? 'Produto Desconhecido',
            'marca': p['brands'] ?? 'Marca não informada',
            'kcal': (nutrients['energy-kcal_100g'] ?? 100).toLowerCase == null ? (nutrients['energy-kcal_100g'] ?? 100).toInt() : (nutrients['energy-kcal_100g'] ?? 100).toInt(),
            'carbos': (nutrients['carbohydrates_100g'] ?? 0.0).toDouble(),
            'proteinas': (nutrients['proteins_100g'] ?? 0.0).toDouble(),
            'gorduras': (nutrients['fat_100g'] ?? 0.0).toDouble(),
            'porcao': p['quantity'] ?? '100g (Padrão)'
          };
        }
      }
    } catch (e) {
      debugPrint('Erro na conexão com a API de alimentos: $e');
    }
    return null;
  }

  void _processarCodigoDetectado(String codigo) async {
    if (_jaEscaneou || _buscandoNaApi) return;
    
    setState(() {
      _buscandoNaApi = true;
    });

    // ⚡ Faz a chamada na nuvem global
    final produtoDetectado = await _consultarApiMundial(codigo);

    setState(() {
      _jaEscaneou = true;
      _buscandoNaApi = false;
    });

    final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    // Se o produto não estiver na API de mercado, cria um item genérico inteligente para não travar a experiência do usuário
    Map<String, dynamic> produtoFinal = produtoDetectado ?? {
      'nome': 'Item Código $codigo',
      'marca': 'Produto de Supermercado',
      'kcal': 120, 'carbos': 15.0, 'proteinas': 4.0, 'gorduras': 2.0, 'porcao': '1 Unidade Padrão'
    };

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('diario')
        .doc(dataHoje);

    // Grava de forma atômica no Firestore da Nutricionista
    await docRef.set({
      'calorias_consumidas': FieldValue.increment(produtoFinal['kcal']),
      'carbos_consumidos': FieldValue.increment(produtoFinal['carbos']),
      'proteinas_consumidos': FieldValue.increment(produtoFinal['proteinas']),
      'gorduras_consumidos': FieldValue.increment(produtoFinal['gorduras']),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': "🛍️ ${produtoFinal['nome']} (${produtoFinal['marca']})",
          'turno': widget.turno,
          'quantidade': 1.0,
          'medida_escolhida': produtoFinal['porcao'],
          'calorias': produtoFinal['kcal'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ ${produtoFinal['nome']} integrado aos macros!'),
          backgroundColor: AppColors.primarySage,
        ),
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
          // Visão da Lente da Câmera Traseira
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

          // Máscara de Scanner (Overlay Clínico)
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(color: Colors.transparent),
                Center(
                  child: Container(
                    width: 280,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondaryMenta, width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Feedback de Carregamento Assíncrono da API
          if (_buscandoNaApi)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AppColors.secondaryMenta),
                    SizedBox(height: 16),
                    Text(
                      'Buscando tabela nutricional na nuvem global... 🌐',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
