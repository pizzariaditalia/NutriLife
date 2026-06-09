import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'features/auth/login_screen.dart';

void main() {
  // Garante que o motor visual do Flutter está pronto antes de tudo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Em vez de rodar o Login direto, roda a nossa Tela de Carregamento Segura
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
      // 1. O Firebase É OBRIGATÓRIO. Ele precisa ligar primeiro.
      await Firebase.initializeApp();

      // 2. Os Lembretes são opcionais. Se o celular bloquear, o app continua funcionando.
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
      // Se der um erro crítico (ex: Firebase não conectou), mostra na tela!
      if (mounted) {
        setState(() => _mensagemErro = 'Erro de Inicialização: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 SE DEU ERRO FATAL: Mostra o texto do erro para resolvermos
    if (_mensagemErro.isNotEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _mensagemErro,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    // 🟢 ENQUANTO CARREGA: Mostra uma tela verde elegante (Splash Screen)
    if (!_tudoPronto) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF3B4D43), // Verde Sage da Nutri Life
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    // ✅ SUCESSO ABSOLUTO: Carrega o aplicativo normalmente
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
