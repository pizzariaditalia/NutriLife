import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import 'custom_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final CustomAuthService _authService = CustomAuthService();
  
  bool _estaCarregando = false;
  bool _ocultarSenha = true;

  Future<void> _entrar() async {
    final email = _emailController.text;
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha email e senha.'),
          backgroundColor: AppColors.accentPeach,
        ),
      );
      return;
    }

    setState(() {
      _estaCarregando = true;
    });

    try {
      // Chama o nosso método de validação customizado no banco de dados
      final String? userId = await _authService.realizarLogin(email, senha);

      if (userId != null) {
        // Login com sucesso! Mostra feedback e navega para o Onboarding
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bem-vindo de volta ao Nutri Life! 🌿'),
            backgroundColor: AppColors.secondaryMenta,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        // Consulta retornou vazia
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciais inválidas. Tente novamente.'),
            backgroundColor: AppColors.accentPeach,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: AppColors.accentPeach,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _estaCarregando = false;
        });
      }
    }
  }

  // Função provisória para criar um usuário de teste caso o banco esteja vazio
  Future<void> _criarContaTeste() async {
    final email = _emailController.text;
    final senha = _senhaController.text;
    
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um email e senha para criar a conta teste.'),
          backgroundColor: AppColors.accentPeach,
        ),
      );
      return;
    }

    setState(() => _estaCarregando = true);
    try {
      await _authService.registrarUsuario('Paciente Teste', email, senha);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada! Agora clique em Entrar.'),
          backgroundColor: AppColors.secondaryMenta,
        ),
      );
    } finally {
      if (mounted) setState(() => _estaCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 80,
                  color: AppColors.primarySage,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nutri Life',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua jornada saudável começa aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primarySage,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Campo de Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primarySage),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo de Senha
                TextField(
                  controller: _senhaController,
                  obscureText: _ocultarSenha,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primarySage),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _ocultarSenha = !_ocultarSenha;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botão de Login
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _estaCarregando ? null : _entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySage,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _estaCarregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.backgroundCreme,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botão Provisório de Cadastro
                TextButton(
                  onPressed: _estaCarregando ? null : _criarContaTeste,
                  child: const Text(
                    'Primeiro acesso? Crie uma conta teste',
                    style: TextStyle(color: AppColors.secondaryMenta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
