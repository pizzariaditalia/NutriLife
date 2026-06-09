import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'features/auth/login_screen.dart';

void main() async {
  // Garante que o motor visual do Flutter está pronto
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🛡️ BLOCO DE SEGURANÇA 1: Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Erro ao inicializar o Firebase: $e');
  }
  
  // 🛡️ BLOCO DE SEGURANÇA 2: Notificações
  try {
    await NotificationService.inicializar();
  } catch (e) {
    debugPrint('Erro ao inicializar as Notificações: $e');
  }

  // 🚀 Desenha o aplicativo na tela independentemente de erros ocultos
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
