import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 FIREBASE REATIVADO OFICIALMENTE!
  await Firebase.initializeApp();

  // Ativando o Cache offline maravilhoso
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const NutriLifeApp());
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
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textDark),
          bodyMedium: TextStyle(color: AppColors.textDark),
        ),
      ),
      // App inicia na Tela de Login para fazermos o cadastro real!
      home: const LoginScreen(),
    );
  }
}
