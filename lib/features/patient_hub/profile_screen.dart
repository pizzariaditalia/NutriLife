import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/features/auth/login_screen.dart'; // Confirme se o caminho do seu Login está correto

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  void _sairDaConta() async {
    // Exibe um diálogo de confirmação antes de sair
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Tem certeza que deseja desconectar do aplicativo?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // Remove todas as telas anteriores e joga para o Login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));

          final dados = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Foto de Perfil
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primarySage.withOpacity(0.2),
                  backgroundImage: dados['foto_perfil'] != null ? NetworkImage(dados['foto_perfil']) : null,
                  child: dados['foto_perfil'] == null ? const Icon(Icons.person, size: 50, color: AppColors.primarySage) : null,
                ),
                const SizedBox(height: 16),
                Text(dados['nome'] ?? 'Paciente', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text(_user!.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 32),

                // Cartão de Informações
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _linhaInfo(Icons.flag_outlined, 'Objetivo', dados['objetivo'] ?? 'Não informado'),
                      const Divider(height: 30),
                      _linhaInfo(Icons.monitor_weight_outlined, 'Peso Atual', '${dados['peso_atual'] ?? '--'} kg'),
                      const Divider(height: 30),
                      _linhaInfo(Icons.height, 'Altura', '${dados['altura'] ?? '--'} m'),
                      const Divider(height: 30),
                      _linhaInfo(Icons.cake_outlined, 'Idade', '${dados['idade'] ?? '--'} anos'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Botão de Sair
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sairDaConta,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _linhaInfo(IconData icone, String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icone, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(titulo, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15)),
      ],
    );
  }
}
