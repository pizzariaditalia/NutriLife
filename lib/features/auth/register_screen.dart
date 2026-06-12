import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../patient_hub/main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _idadeCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _hobbyCtrl = TextEditingController();

  String _objetivoSelecionado = 'Emagrecimento';
  bool _carregando = false;

  final List<String> _opcoesObjetivos = [
    'Emagrecimento',
    'Hipertrofia',
    'Gestante ou Tentante',
    'Saúde & Longevidade'
  ];

  void _executarCadastroEstrategico() async {
    if (_emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty || _nomeCtrl.text.isEmpty || _pesoCtrl.text.isEmpty || _alturaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha os dados clínicos obrigatórios! ⚠️')));
      return;
    }

    setState(() => _carregando = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text.trim(),
      );

      String uid = userCredential.user!.uid;

      double peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 70.0;
      double altura = double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 1.70;
      int idade = int.tryParse(_idadeCtrl.text) ?? 25;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nome': _nomeCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'idade': idade,
        'altura': altura,
        'peso_inicial': peso,
        'peso_atual': peso,
        'objetivo': _objetivoSelecionado,
        'hobby': _hobbyCtrl.text.trim(),
        'cadastro_completo': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('usuario_logado', true);

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()), (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Perfil de Onboarding', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🚀 LOGO OFICIAL ADICIONADA NO TOPO DO CADASTRO
              Center(
                child: Image.asset(
                  'image/icon.png',
                  height: 90,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Monte o seu Perfil Clínico 🩺', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 6),
              const Text('Essas informações calcularão suas calorias automaticamente.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 32),

              _buildInput(_nomeCtrl, 'Nome Completo', Icons.person_outline, TextInputType.name),
              _buildInput(_emailCtrl, 'E-mail do Usuário', Icons.mail_outline, TextInputType.emailAddress),
              _buildInput(_senhaCtrl, 'Senha de Acesso', Icons.lock_outline, TextInputType.text, obscuro: true),
              
              Row(
                children: [
                  Expanded(child: _buildInput(_idadeCtrl, 'Idade', Icons.calendar_today_outlined, TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInput(_alturaCtrl, 'Altura (m)', Icons.height, const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              
              Row(
                children: [
                  Expanded(child: _buildInput(_pesoCtrl, 'Peso (kg)', Icons.scale_outlined, const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInput(_hobbyCtrl, 'Seu Hobby', Icons.star_border, TextInputType.text)),
                ],
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.backgroundCreme, borderRadius: BorderRadius.circular(16)),
                child: DropdownButtonFormField<String>(
                  value: _objetivoSelecionado,
                  decoration: const InputDecoration(labelText: 'Qual seu objetivo atual?', border: InputBorder.none),
                  items: _opcoesObjetivos.map((String obj) {
                    return DropdownMenuItem<String>(value: obj, child: Text(obj));
                  }).toList(),
                  onChanged: (valor) => setState(() => _objetivoSelecionado = valor ?? 'Emagrecimento'),
                ),
              ),
              const SizedBox(height: 16),

              _carregando 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primarySage))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySage, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    onPressed: _executarCadastroEstrategico,
                    child: const Text('Concluir e Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData ico, TextInputType tipo, {bool obscuro = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(color: AppColors.backgroundCreme, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: ctrl,
        keyboardType: tipo,
        obscureText: obscuro,
        style: const TextStyle(color: AppColors.textDark),
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(ico, color: Colors.grey), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}
