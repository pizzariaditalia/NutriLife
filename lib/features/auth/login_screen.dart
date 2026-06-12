import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../patient_hub/main_navigation_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _senhaCtrl = TextEditingController();
  bool _lembrarDeMim = true;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _verificarLoginSalvo();
  }

  void _verificarLoginSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    bool logado = prefs.getBool('usuario_logado') ?? false;

    if (logado && FirebaseAuth.instance.currentUser != null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
      }
    }
  }

  void _entrar() async {
    if (_emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty) return;
    setState(() => _carregando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );

      if (_lembrarDeMim) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('usuario_logado', true);
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🚀 LOGO OFICIAL NUTRI LIFE INJECTADA
                Image.asset(
                  'image/icon.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.eco, size: 72, color: AppColors.primarySage);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nutri Life',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5),
                ),
                const SizedBox(height: 48),
                
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primarySage, width: 2)),
                  ),
                ),
                const SizedBox(height: 18),
                
                TextField(
                  controller: _senhaCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primarySage, width: 2)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _lembrarDeMim,
                        activeColor: AppColors.primarySage,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (valor) => setState(() => _lembrarDeMim = valor ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Lembrar de mim', style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 32),

                _carregando 
                  ? const CircularProgressIndicator(color: AppColors.primarySage)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySage,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _entrar,
                          child: const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('Criar Nova Conta', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold, fontSize: 14)),
                        )
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
