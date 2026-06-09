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
  int _goalHours = 16; // Meta padrão: 16 horas (Protocolo 16:8)
  
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

  // 📡 Busca no Firebase se o usuário já tem um jejum rodando na nuvem
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

  // ⏱️ Motor do cronômetro que atualiza a tela a cada segundo
  void _iniciarCronometroVisual() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        setState(() {
          _tempoDecorrido = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  // 🟢 Ação de INICIAR o Jejum
  void _iniciarJejum() async {
    final agora = DateTime.now();
    setState(() {
      _isFasting = true;
      _startTime = agora;
      _tempoDecorrido = Duration.zero;
    });
    
    _iniciarCronometroVisual();

    // Salva na nuvem para não perder se fechar o app
    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('jejum_atual').doc('status').set({
      'isFasting': true,
      'startTime': agora.millisecondsSinceEpoch,
      'goalHours': _goalHours,
    });
  }

  // 🔴 Ação de ENCERRAR o Jejum e salvar no histórico
  void _encerrarJejum() async {
    _timer?.cancel();
    
    final fim = DateTime.now();
    final totalHoras = _tempoDecorrido.inMinutes / 60.0;

    // Salva no histórico da Nutricionista
    if (_tempoDecorrido.inMinutes > 5) { // Só salva se durou mais de 5 minutos
      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('historico_jejum').add({
        'inicio': _startTime?.millisecondsSinceEpoch,
        'fim': fim.millisecondsSinceEpoch,
        'duracao_horas': totalHoras,
        'meta_atingida': totalHoras >= _goalHours,
      });
    }

    // Zera o status atual
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

  String _formatarDuracao(Duration duracao) {
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    final horas = doisDigitos(duracao.inHours);
    final minutos = doisDigitos(duracao.inMinutes.remainder(60));
    final segundos = doisDigitos(duracao.inSeconds.remainder(60));
    return "$horas:$minutos:$segundos";
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo da porcentagem do círculo
    final totalSegundosMeta = _goalHours * 3600;
    final segundosDecorridos = _tempoDecorrido.inSeconds;
    double progresso = segundosDecorridos / totalSegundosMeta;
    if (progresso > 1.0) progresso = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121418), // Visual Dark Premium
      appBar: AppBar(
        title: const Text('Rastreador de Jejum', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SELETOR DE META DE HORAS
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

            // CRONÔMETRO CIRCULAR (ESTILO APP ZERO)
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

            // BOTÃO DE AÇÃO
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
          ],
        ),
      ),
    );
  }
}
