import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({Key? key}) : super(key: key);

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  
  bool _isFasting = false;
  DateTime? _startTime;
  int _goalHours = 16; 
  
  Timer? _timer;
  Duration _tempoDecorrido = Duration.zero;

  @override
  void initState() {
    super.initState();
    _carregarEstadoDoJejum();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _carregarEstadoDoJejum() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('jejum_atual').doc('status').get();
    
    if (doc.exists && doc.data() != null) {
      final dados = doc.data()!;
      if (dados['isFasting'] == true) {
        setState(() {
          _isFasting = true;
          _startTime = DateTime.fromMillisecondsSinceEpoch(dados['startTime']);
          _goalHours = dados['goalHours'] ?? 16;
        });
        _iniciarCronometroVisual();
      }
    }
  }

  void _iniciarCronometroVisual() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        setState(() {
          _tempoDecorrido = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  void _iniciarJejum() async {
    final agora = DateTime.now();
    setState(() {
      _isFasting = true;
      _startTime = agora;
      _tempoDecorrido = Duration.zero;
    });
    
    _iniciarCronometroVisual();

    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('jejum_atual').doc('status').set({
      'isFasting': true,
      'startTime': agora.millisecondsSinceEpoch,
      'goalHours': _goalHours,
    });
  }

  void _encerrarJejum() async {
    _timer?.cancel();
    
    final fim = DateTime.now();
    final totalHoras = _tempoDecorrido.inMinutes / 60.0;

    if (_tempoDecorrido.inMinutes > 5) { 
      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('historico_jejum').add({
        'inicio': _startTime?.millisecondsSinceEpoch,
        'fim': fim.millisecondsSinceEpoch,
        'duracao_horas': totalHoras,
        'meta_atingida': totalHoras >= _goalHours,
      });
    }

    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('jejum_atual').doc('status').set({
      'isFasting': false,
    });

    setState(() {
      _isFasting = false;
      _startTime = null;
      _tempoDecorrido = Duration.zero;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jejum encerrado! Total: ${totalHoras.toStringAsFixed(1)}h 🌟'), backgroundColor: AppColors.primarySage),
      );
    }
  }

  // 🚀 PONTO 1: FUNÇÃO E MODAL PARA REGISTRO MANUAL DE JEJUM
  void _abrirModalJejumManual() {
    final horasCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2126),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Registro Manual', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esqueceu de ligar o cronômetro? Registre as horas de jejum que você já concluiu.', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 20),
            TextField(
              controller: horasCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Total de Horas',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'Ex: 16',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPeach, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              int horas = int.tryParse(horasCtrl.text) ?? 0;
              if (horas > 0) {
                final fim = DateTime.now();
                final inicio = fim.subtract(Duration(hours: horas));

                await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('historico_jejum').add({
                  'inicio': inicio.millisecondsSinceEpoch,
                  'fim': fim.millisecondsSinceEpoch,
                  'duracao_horas': horas.toDouble(),
                  'meta_atingida': horas >= _goalHours,
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Jejum de ${horas}h registrado com sucesso!'), backgroundColor: AppColors.primarySage));
                }
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatarDuracao(Duration duracao) {
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    final horas = doisDigitos(duracao.inHours);
    final minutos = doisDigitos(duracao.inMinutes.remainder(60));
    final segundos = doisDigitos(duracao.inSeconds.remainder(60));
    return "$horas:$minutos:$segundos";
  }

  @override
  Widget build(BuildContext context) {
    final totalSegundosMeta = _goalHours * 3600;
    final segundosDecorridos = _tempoDecorrido.inSeconds;
    double progresso = segundosDecorridos / totalSegundosMeta;
    if (progresso > 1.0) progresso = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121418), 
      appBar: AppBar(
        title: const Text('Rastreador de Jejum', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isFasting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _goalHours,
                      dropdownColor: const Color(0xFF1E2126),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      items: [12, 14, 16, 18, 20, 24].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Protocolo $value:8', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (novoValor) {
                        if (novoValor != null) setState(() => _goalHours = novoValor);
                      },
                    ),
                  ),
                ),
              
              const SizedBox(height: 40),
          
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: _isFasting ? progresso : 0.0,
                      strokeWidth: 16,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      color: progresso >= 1.0 ? AppColors.secondaryMenta : AppColors.accentPeach,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _isFasting ? "TEMPO DECORRIDO" : "PRONTO PARA INICIAR",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isFasting ? _formatarDuracao(_tempoDecorrido) : "00:00:00",
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                      if (_isFasting) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Meta: $_goalHours horas",
                          style: TextStyle(color: progresso >= 1.0 ? AppColors.secondaryMenta : Colors.grey.shade500, fontSize: 14),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
          
              const SizedBox(height: 60),
          
              GestureDetector(
                onTap: _isFasting ? _encerrarJejum : _iniciarJejum,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  decoration: BoxDecoration(
                    color: _isFasting ? Colors.white.withOpacity(0.1) : AppColors.accentPeach,
                    borderRadius: BorderRadius.circular(30),
                    border: _isFasting ? Border.all(color: Colors.white30) : null,
                  ),
                  child: Text(
                    _isFasting ? 'Encerrar Jejum' : 'Iniciar Jejum',
                    style: TextStyle(
                      color: _isFasting ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 🚀 PONTO 1: BOTÃO DE REGISTRO MANUAL DEBAIXO DO PRINCIPAL
              if (!_isFasting) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _abrirModalJejumManual,
                  icon: const Icon(Icons.history, color: Colors.white54, size: 18),
                  label: const Text('Registrar Jejum Manualmente', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
