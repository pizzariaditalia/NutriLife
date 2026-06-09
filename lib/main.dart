import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'features/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppInicializador());
}

class AppInicializador extends StatefulWidget {
  const AppInicializador({Key? key}) : super(key: key);

  @override
  State<AppInicializador> createState() => _AppInicializadorState();
}

class _AppInicializadorState extends State<AppInicializador> {
  bool _tudoPronto = false;
  String _mensagemErro = '';

  @override
  void initState() {
    super.initState();
    _ligarSistemasDoAplicativo();
  }

  Future<void> _ligarSistemasDoAplicativo() async {
    try {
      // 1. Liga o Firebase no modo tradicional do Android
      await Firebase.initializeApp();

      // 2. Tenta ligar os Alarmes
      try {
        await NotificationService.inicializar();
      } catch (erroAlarme) {
        debugPrint('Aviso: Lembretes falharam ao iniciar - $erroAlarme');
      }

      // Tudo ligou com sucesso! Libera o aplicativo.
      if (mounted) {
        setState(() => _tudoPronto = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mensagemErro = 'Erro de Inicialização do Firebase:\n\n$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mensagemErro.isNotEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Text(
                  _mensagemErro,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!_tudoPronto) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF3B4D43),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Nutri Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
