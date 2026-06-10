import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutri_life/core/theme/app_colors.dart';
import 'package:nutri_life/core/services/imgbb_service.dart';

class EvolutionGalleryScreen extends StatefulWidget {
  const EvolutionGalleryScreen({Key? key}) : super(key: key);

  @override
  State<EvolutionGalleryScreen> createState() => _EvolutionGalleryScreenState();
}

class _EvolutionGalleryScreenState extends State<EvolutionGalleryScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final _picker = ImagePicker();
  String _uploadingKey = '';

  void _selecionarImagem(String chaveSlot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primarySage),
              title: const Text('Escolher da Galeria do Celular'),
              onTap: () => _fazerUploadSlot(chaveSlot, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primarySage),
              title: const Text('Tirar Foto com a Câmera'),
              onTap: () => _fazerUploadSlot(chaveSlot, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _fazerUploadSlot(String chaveSlot, ImageSource deOnde) async {
    Navigator.pop(context);
    // 🚀 CORRIGIDO: de imageSource: para source:
    final XFile? foto = await _picker.pickImage(source: deOnde, imageQuality: 70);
    
    if (foto != null) {
      setState(() => _uploadingKey = chaveSlot);
      
      String? linkUrl = await ImgBbService.uploadImage(foto);
      
      if (linkUrl != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_userId)
            .collection('galeria')
            .doc('fotos_atuais')
            .set({chaveSlot: linkUrl}, SetOptions(merge: true));
      }
      
      if (mounted) setState(() => _uploadingKey = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Galeria de Evolução visual', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('galeria').doc('fotos_atuais').snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> fotos = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            fotos = snapshot.data!.data() as Map<String, dynamic>;
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Sua Jornada Visual 📸', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text('Monitore suas mudanças físicas. Suas fotos estão seguras e privadas.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 32),

              const Text('FOTOS DE ANTES (INÍCIO)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primarySage, letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSlotFoto('antes_1', fotos['antes_1'])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSlotFoto('antes_2', fotos['antes_2'])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSlotFoto('antes_3', fotos['antes_3'])),
                ],
              ),

              const SizedBox(height: 36),

              const Text('FOTOS DE DEPOIS (ATUAL)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentPeach, letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSlotFoto('depois_1', fotos['depois_1'])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSlotFoto('depois_2', fotos['depois_2'])),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSlotFoto('depois_3', fotos['depois_3'])),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlotFoto(String chaveSlot, String? urlString) {
    bool carregandoEsteSlot = _uploadingKey == chaveSlot;

    return AspectRatio(
      aspectRatio: 1, 
      child: GestureDetector(
        onTap: carregandoEsteSlot ? null : () => _selecionarImagem(chaveSlot),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            image: urlString != null ? DecorationImage(image: NetworkImage(urlString), fit: BoxFit.cover) : null,
          ),
          child: urlString == null 
              ? Center(
                  child: carregandoEsteSlot 
                      ? const CircularProgressIndicator(color: AppColors.primarySage)
                      : Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 26),
                )
              : const SizedBox(),
        ),
      ),
    );
  }
}
