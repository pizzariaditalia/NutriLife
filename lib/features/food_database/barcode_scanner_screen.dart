import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String turno;
  const BarcodeScannerScreen({Key? key, required this.turno}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _laserAnimation;

  final List<Map<String, dynamic>> _produtosSupermercado = [
    {
      'codigo': '7891000123456',
      'nome': 'Iogurte Proteico Skyr',
      'marca': 'Nestlé',
      'kcal': 95, 'carbos': 4.0, 'proteinas': 15.0, 'gorduras': 0.5,
      'porcao': '1 Pote (150g)'
    },
    {
      'codigo': '7892000654321',
      'nome': 'Barra de Proteína Chocolate',
      'marca': 'IntegralMedica',
      'kcal': 190, 'carbos': 12.0, 'proteinas': 16.0, 'gorduras': 6.5,
      'porcao': '1 Unidade (45g)'
    },
    {
      'codigo': '7893000987654',
      'nome': 'Atum Sólido em Natural',
      'marca': 'Gomes da Costa',
      'kcal': 120, 'carbos': 0.0, 'proteinas': 26.0, 'gorduras': 1.8,
      'porcao': '1 Lata (120g)'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 220.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _computarProdutoEscaneado(Map<String, dynamic> produto) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
    final agora = DateTime.now();
    final dataHoje = "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";

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
          'nome': "[Barcode] ${produto['nome']} (${produto['marca']})",
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
        SnackBar(
          content: Text('✨ ${produto['nome']} lido e adicionado ao ${widget.turno}!'),
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
        title: const Text('Leitor de Código', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Posicione o código de barras do alimento dentro da área demarcada',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 260,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2), // CORRIGIDO
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _laserAnimation.value + 10,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.accentPeach,
                          boxShadow: [
                            BoxShadow(color: AppColors.accentPeach.withOpacity(0.8), blurRadius: 8, spreadRadius: 2)
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Simular leitura de produtos do mercado:',
            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _produtosSupermercado.length,
              itemBuilder: (context, index) {
                final prod = _produtosSupermercado[index];
                return Card(
                  color: Colors.grey.shade900,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () => _computarProdutoEscaneado(prod),
                    leading: const Icon(Icons.document_scanner_rounded, color: AppColors.secondaryMenta),
                    title: Text(prod['nome'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("${prod['marca']} • ${prod['codigo']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    trailing: Text("+ ${prod['kcal']} kcal", style: const TextStyle(color: AppColors.accentPeach, fontWeight: FontWeight.bold, fontSize: 13)),
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
