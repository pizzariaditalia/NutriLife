import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 LIGAÇÃO DIRETA E BLINDADA DO FIREBASE
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDDonDjAPJzUQSDN6dBrG4p7fhI6YlqTSY',
        appId: '1:210549500065:android:702ee7b33d41b046e968e0',
        messagingSenderId: '210549500065',
        projectId: 'nutri-life-45b6c',
      ),
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    runApp(const NutriLifeApp());
  } catch (erro) {
    // Mantemos o Raio-X por segurança
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Erro: $erro', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}

class NutriLifeApp extends StatelessWidget {
  const NutriLifeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutri Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primarySage,
        scaffoldBackgroundColor: AppColors.backgroundCreme,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primarySage,
          secondary: AppColors.secondaryMenta,
          error: AppColors.accentPeach,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primarySage,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.backgroundCreme),
          titleTextStyle: TextStyle(
            color: AppColors.backgroundCreme,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
