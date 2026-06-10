import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/core/services/imgbb_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final _picker = ImagePicker();
  bool _enviandoFoto = false;

  void _alterarFotoPerfil() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primarySage),
              title: const Text('Escolher da Galeria'),
              onTap: () => _processarOrigemImagem(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primarySage),
              title: const Text('Tirar Nova Foto'),
              onTap: () => _processarOrigemImagem(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _processarOrigemImagem(ImageSource deOnde) async {
    Navigator.pop(context);
    // 🚀 CORRIGIDO: de imageSource: para source:
    final XFile? imagemSelecionada = await _picker.pickImage(source: deOnde, imageQuality: 70);
    
    if (imagemSelecionada != null) {
      setState(() => _enviandoFoto = true);
      
      String? urlNuvem = await ImgBbService.uploadImage(imagemSelecionada);
      
      if (urlNuvem != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set({
          'foto_perfil': urlNuvem,
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil atualizada com sucesso! ✨'), backgroundColor: AppColors.primarySage));
        }
      }
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Perfil Clínico', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
          
          Map<String, dynamic> dados = {};
          if (snapshot.data!.exists) {
            dados = snapshot.data!.data() as Map<String, dynamic>;
          }

          String? fotoUrl = dados['foto_perfil'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                        child: _enviandoFoto 
                            ? const CircularProgressIndicator(color: AppColors.primarySage)
                            : (fotoUrl == null ? const Icon(Icons.person, size: 65, color: Colors.grey) : null),
                      ),
                      InkWell(
                        onTap: _enviandoFoto ? null : _alterarFotoPerfil,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primarySage,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildCampoDados('Nome Completo', dados['nome'] ?? 'Bruno Resende dos Santos'),
                _buildCampoDados('Idade', dados['idade']?.toString() ?? '29'),
                _buildCampoDados('Objetivo', dados['objective'] ?? 'Emagrecimento'),
                _buildCampoDados('Altura (m)', dados['altura']?.toString() ?? '1.74'),
                _buildCampoDados('Peso Inicial (kg)', dados['peso_inicial']?.toString() ?? '87.4'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampoDados(String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
