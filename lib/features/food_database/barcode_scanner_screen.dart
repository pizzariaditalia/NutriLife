import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String turno;
  const BarcodeScannerScreen({Key? key, required this.turno}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _jaEscaneou = false;

  // Dicionário de produtos premium reais associados aos códigos de barras de mercado
  final Map<String, Map<String, dynamic>> _produtosCadastrados = {
    '7891000123456': {
      'nome': 'Iogurte Proteico Skyr',
      'marca': 'Nestlé',
      'kcal': 95, 'carbos': 4.0, 'proteinas': 15.0, 'gorduras': 0.5, 'porcao': '1 Pote (150g)'
    },
    '7892000654321': {
      'nome': 'Barra de Proteína Chocolate',
      'marca': 'IntegralMedica',
      'kcal': 190, 'carbos': 12.0, 'proteinas': 16.0, 'gorduras': 6.5, 'porcao': '1 Unidade (45g)'
    },
    '7893000987654': {
      'nome': 'Atum Sólido em Natural',
      'marca': 'Gomes da Costa',
      'kcal': 120, 'carbos': 0.0, 'proteinas': 26.0, 'gorduras': 1.8, 'porcao': '1 Lata (120g)'
    }
  };

  void _processarCodigoDetectado(String codigo) async {
    if (_jaEscaneou) return;
    setState(() => _jaEscaneou = true);

    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

    // Se encontrar o produto na base, computa as propriedades macro reais; caso contrário, cria um item genérico
    Map<String, dynamic> produto = _produtosCadastrados[codigo] ?? {
      'nome': 'Produto Desconhecido',
      'marca': 'Supermercado',
      'kcal': 150, 'carbos': 15.0, 'proteinas': 5.0, 'gorduras': 3.0, 'porcao': '1 Porção Padrão'
    };

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('diario')
        .doc(dataHoje);

    await docRef.set({
      'calorias_consumidas': FieldValue.increment(produto['kcal']),
      'carbos_consumidos': FieldValue.increment(produto['carbos']),
      'proteinas_consumidos': FieldValue.increment(produto['proteinas']),
      'gorduras_consumidos': FieldValue.increment(produto['gorduras']),
      'historico_alimentos': FieldValue.arrayUnion([
        {
          'nome': "[Escaner] ${produto['nome']}",
          'turno': widget.turno,
          'quantidade': 1.0,
          'medida_escolhida': produto['porcao'],
          'calorias': produto['kcal'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      ])
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ ${produto['nome']} processado com sucesso!'), backgroundColor: AppColors.primarySage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Código de Barras', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 📸 INSTANCIAÇÃO DA CÂMERA EM TEMPO REAL
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
          // Máscara Visual de Foco (Overlay Premium)
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
                      borderRadius: BorderRadius.circular(20),
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
                border: Border.all(color: AppColors.accentPeach, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
