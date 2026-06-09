import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import 'profile_screen.dart';
import 'fasting_screen.dart';
import 'grocery_list_screen.dart';
import 'evolution_gallery_screen.dart';
import 'habits_screen.dart'; // NOVO IMPORT

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
        title: const Text('Registrar Peso Atual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: TextField(
          controller: txtController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Ex: 78.5', suffixText: 'kg', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primarySage))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage),
            onPressed: () async {
              if (txtController.text.isNotEmpty) {
                double? pesoDigitado = double.tryParse(txtController.text.replaceAll(',', '.'));
                if (pesoDigitado != null) {
                  final agora = DateTime.now();
                  final dataKey = _getTodayDateKey();
                  
                  await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('historico_peso').doc(dataKey).set({
                    'peso': pesoDigitado, 'data': dataKey, 'timestamp': agora.millisecondsSinceEpoch,
                    'mes': const ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'][agora.month - 1],
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peso registrado! 📈'), backgroundColor: AppColors.primarySage));
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('diario').doc(dataHoje).snapshots(),
        builder: (context, snapshot) {
          int caloriasConsumidas = 0, metaCalorias = 2000, aguaConsumida = 0, metaAgua = 2500;
          double carbos = 0, proteinas = 0, gorduras = 0;

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

          int caloriasRestantes = (metaCalorias - caloriasConsumidas).clamp(0, 9999);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo de Hoje', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 20),
                _ConstruirCardCaloriasPremium(consumido: caloriasConsumidas, meta: metaCalorias, restante: caloriasRestantes, carbos: carbos, proteinas: proteinas, gorduras: gorduras),
                const SizedBox(height: 24),
                _ConstruirCardAguaGamificado(consumido: aguaConsumida, meta: metaAgua, userId: _userId, dataKey: dataHoje),
                const SizedBox(height: 24),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('historico_peso').orderBy('timestamp', descending: true).limit(1).snapshots(),
                  builder: (context, pesoSnapshot) {
                    String pesoTexto = "Nenhum registro";
                    if (pesoSnapshot.hasData && pesoSnapshot.data!.docs.isNotEmpty) {
                      final ultimoDoc = pesoSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      pesoTexto = "${ultimoDoc['peso']} kg";
                    }
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Evolução de Peso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)), const SizedBox(height: 4), Text('Último registro: $pesoTexto', style: const TextStyle(fontSize: 13, color: AppColors.primarySage, fontWeight: FontWeight.bold))]),
                          ElevatedButton.icon(onPressed: () => _abrirDialogoRegistrarPeso(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage.withOpacity(0.1), shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.scale_rounded, color: AppColors.primarySage, size: 18), label: const Text('Pesar', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('Ferramentas Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EvolutionGalleryScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                    child: Row(
                      children: [
                        const Icon(Icons.compare_rounded, color: AppColors.accentPeach, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Galeria de Evolução', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Visualize seu Antes e Depois visual', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _construirCardTool(Icons.timer_outlined, 'Jejum', 'Rastreador', AppColors.accentPeach, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FastingScreen())))),
                    const SizedBox(width: 16),
                    Expanded(child: _construirCardTool(Icons.shopping_cart_outlined, 'Compras', 'Lista Inteligente', AppColors.secondaryMenta, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GroceryListScreen())))),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔔 NOVO BOTÃO DE ALERTAS DO PROJETO NA BASE DA GRADE
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HabitsScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primarySage, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notification_add_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 12),
                        Text('Ativar Lembretes da Rotina 🔔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirCardTool(IconData icone, String titulo, String sub, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1E2126), borderRadius: BorderRadius.circular(20)),
        child: Column( col: CrossAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Icon(icone, color: cor, size: 32), const SizedBox(height: 12), Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12))],
        ),
      ),
    );
  }
}

class _ConstruirCardCaloriasPremium extends StatelessWidget {
  final int consumido, meta, restante;
  final double carbos, proteinas, gorduras;
  const _ConstruirCardCaloriasPremium({Key? key, required this.consumido, required this.meta, required this.restante, required this.carbos, required this.proteinas, required this.gorduras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progressoCalorias = consumido / meta;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column( children: [
          Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [ _infoItem('Consumido', '$consumido', Icons.local_dining), Stack( alignment: Alignment.center, children: [ SizedBox(width: 100, height: 100, child: CircularProgressIndicator(value: progressoCalorias.clamp(0.0, 1.0), strokeWidth: 10, backgroundColor: Colors.grey.shade200, color: AppColors.primarySage)), Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$restante', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)), Text('kcal\nrestantes', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500))],)],), _infoItem('Meta', '$meta', Icons.flag),],),
          const SizedBox(height: 24), const Divider(height: 1), const SizedBox(height: 20),
          Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_barraMacro('Carbos', carbos, 200, AppColors.secondaryMenta), _barraMacro('Proteínas', proteinas, 150, AppColors.primarySage), _barraMacro('Gorduras', gorduras, 65, AppColors.accentPeach)],
          ),
        ],),);
  }
  Widget _infoItem(String titulo, String valor, IconData icone) { return Column(children: [Icon(icone, color: Colors.grey.shade400, size: 20), const SizedBox(height: 4), Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)), Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]); }
  Widget _barraMacro(String titulo, double atual, double meta, Color cor) { double progresso = atual / meta; return Column(children: [Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 8), Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progresso.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(10))))), const SizedBox(height: 8), Text('${atual.toInt()}/${meta.toInt()}g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),]); }
}
class _ConstruirCardAguaGamificado extends StatelessWidget {
  final int consumido, meta;
  final String userId, dataKey;
  const _ConstruirCardAguaGamificado({Key? key, required this.consumido, required this.meta, required this.userId, required this.dataKey}) : super(key: key);
  void _adicionarCopoAgua() async { await FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('diario').doc(dataKey).set({'agua_consumida': FieldValue.increment(250), 'meta_agua': meta}, SetOptions(merge: true)); }
  @override
  Widget build(BuildContext context) { return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Hidratação', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('$consumido / $meta ml', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14))]), ElevatedButton(onPressed: _adicionarCopoAgua, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('+ Copo'))],),); }
}
