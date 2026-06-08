import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Tenta ligar o Firebase
    await Firebase.initializeApp();

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Se der tudo certo, roda o app normal
    runApp(const NutriLifeApp());
  } catch (erro) {
    // SE O FIREBASE FALHAR: Captura o erro e mostra na tela!
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Ocorreu um erro no Firebase:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      erro.toString(),
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
