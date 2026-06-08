import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import 'profile_screen.dart'; // Import adicionado no lugar correto!

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';

  String _getTodayDateKey() {
    final agora = DateTime.now();
    return "${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}";
  }

  void _abrirDialogoRegistrarPeso(BuildContext context) {
    final txtController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Peso Actual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: TextField(
          controller: txtController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Ex: 78.5',
            suffixText: 'kg',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primarySage)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage),
            onPressed: () async {
              if (txtController.text.isNotEmpty) {
                double? pesoDigitado = double.tryParse(txtController.text.replaceAll(',', '.'));
                if (pesoDigitado != null) {
                  final agora = DateTime.now();
                  final dataKey = _getTodayDateKey();
                  
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(_userId)
                      .collection('historico_peso')
                      .doc(dataKey)
                      .set({
                    'peso': pesoDigitado,
                    'data': dataKey,
                    'timestamp': agora.millisecondsSinceEpoch,
                    'mes': _getMesAbreviado(agora.month),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Peso registrado com sucesso! 📈'), backgroundColor: AppColors.primarySage),
                    );
                  }
                }
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getMesAbreviado(int mes) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = _getTodayDateKey();

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Painel'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_userId)
            .collection('diario')
            .doc(dataHoje)
            .snapshots(),
        builder: (context, snapshot) {
          int caloriasConsumidas = 0;
          int metaCalorias = 2000;
          double carbos = 0;
          double proteinas = 0;
          double gorduras = 0;
          int aguaConsumida = 0;
          int metaAgua = 2500;

          if (snapshot.hasData && snapshot.data!.exists) {
            final dados = snapshot.data!.data() as Map<String, dynamic>;
            caloriasConsumidas = dados['calorias_consumidas'] ?? 0;
            metaCalorias = dados['meta_calorias'] ?? 2000;
            carbos = (dados['carbos_consumidos'] ?? 0).toDouble();
            proteinas = (dados['proteinas_consumidos'] ?? 0).toDouble();
            gorduras = (dados['gorduras_consumidos'] ?? 0).toDouble();
            aguaConsumida = dados['agua_consumida'] ?? 0;
            metaAgua = dados['meta_agua'] ?? 2500;
          }

          int caloriasRestantes = metaCalorias - caloriasConsumidas;
          if (caloriasRestantes < 0) caloriasRestantes = 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo de Hoje',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 20),
                
                _ConstruirCardCaloriasPremium(
                  consumido: caloriasConsumidas,
                  meta: metaCalorias,
                  restante: caloriasRestantes,
                  carbos: carbos,
                  proteinas: proteinas,
                  gorduras: gorduras,
                ),
                
                const SizedBox(height: 24),
                
                _ConstruirCardAguaGamificado(
                  consumido: aguaConsumida,
                  meta: metaAgua,
                  userId: _userId,
                  dataKey: dataHoje,
                ),
                
                const SizedBox(height: 24),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(_userId)
                      .collection('historico_peso')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, pesoSnapshot) {
                    String pesoTexto = "Nenhum registro";
                    if (pesoSnapshot.hasData && pesoSnapshot.data!.docs.isNotEmpty) {
                      final ultimoDoc = pesoSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      pesoTexto = "${ultimoDoc['peso']} kg";
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Evolução de Peso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              Text('Último registro: $pesoTexto', style: const TextStyle(fontSize: 13, color: AppColors.primarySage, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _abrirDialogoRegistrarPeso(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySage.withOpacity(0.1),
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.scale_rounded, color: AppColors.primarySage, size: 18),
                            label: const Text('Pesar', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConstruirCardCaloriasPremium extends StatelessWidget {
  final int consumido;
  final int meta;
  final int restante;
  final double carbos;
  final double proteinas;
  final double gorduras;

  const _ConstruirCardCaloriasPremium({
    Key? key,
    required this.consumido,
    required this.meta,
    required this.restante,
    required this.carbos,
    required this.proteinas,
    required this.gorduras,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progressoCalorias = consumido / meta;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem('Consumido', '$consumido', Icons.local_dining),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progressoCalorias.clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.primarySage,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$restante', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text('kcal\nrestantes', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              _infoItem('Meta', '$meta', Icons.flag),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _barraMacro('Carbos', carbos, 200, AppColors.secondaryMenta),
              _barraMacro('Proteínas', proteinas, 150, AppColors.primarySage),
              _barraMacro('Gorduras', gorduras, 65, AppColors.accentPeach),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String titulo, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: Colors.grey.shade400, size: 20),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _barraMacro(String titulo, double atual, double meta, Color cor) {
    double progresso = atual / meta;
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: 60, height: 6,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progresso.clamp(0.0, 1.0),
            child: Container(decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(height: 8),
        Text('${atual.toInt()}/${meta.toInt()}g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _ConstruirCardAguaGamificado extends StatelessWidget {
  final int consumido;
  final int meta;
  final String userId;
  final String dataKey;

  const _ConstruirCardAguaGamificado({
    Key? key,
    required this.consumido,
    required this.meta,
    required this.userId,
    required this.dataKey,
  }) : super(key: key);

  void _adicionarCopoAgua() async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('diario')
        .doc(dataKey);

    await docRef.set({
      'agua_consumida': FieldValue.increment(250),
      'meta_agua': meta,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hidratação', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$consumido / $meta ml', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
            ],
          ),
          ElevatedButton(
            onPressed: _adicionarCopoAgua,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('+ Copo'),
          ),
        ],
      ),
    );
  }
}
