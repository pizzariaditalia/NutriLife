import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
// 🚀 CORREÇÃO 1: Importação absoluta (acha o arquivo em qualquer lugar)
import 'package:nutri_life/main_navigation_screen.dart';

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
        // 🚀 CORREÇÃO 2: Sem o 'const', garantindo a compilação lisa
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainNavigationScreen()));
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainNavigationScreen()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _criarConta() async {
    if (_emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty) return;
    setState(() => _carregando = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );
      
      if (_lembrarDeMim) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('usuario_logado', true);
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainNavigationScreen()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar: ${e.message}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primarySage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco, size: 60, color: AppColors.primarySage),
                const SizedBox(height: 16),
                const Text('Nutri Life', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'E-mail', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _senhaCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Senha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Checkbox(
                      value: _lembrarDeMim,
                      activeColor: AppColors.primarySage,
                      onChanged: (valor) => setState(() => _lembrarDeMim = valor ?? true),
                    ),
                    const Text('Lembrar de mim', style: TextStyle(color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 16),

                _carregando 
                  ? const CircularProgressIndicator(color: AppColors.primarySage)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _entrar,
                          child: const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _criarConta,
                          child: const Text('Criar Nova Conta', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold)),
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
