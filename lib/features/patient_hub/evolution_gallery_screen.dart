import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class EvolutionGalleryScreen extends StatefulWidget {
  const EvolutionGalleryScreen({Key? key}) : super(key: key);

  @override
  State<EvolutionGalleryScreen> createState() => _EvolutionGalleryScreenState();
}

class _EvolutionGalleryScreenState extends State<EvolutionGalleryScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final ImagePicker _picker = ImagePicker();
  
  String? _photoUrlAntes;
  String? _dataAntes;
  String? _photoUrlDepois;
  String? _dataDepois;
  bool _enviandoFoto = false;

  @override
  void initState() {
    super.initState();
    _carregarFotosEvolucao();
  }

  // 📡 CARREGA DADOS DO FIRESTORE: Pega os links das fotos salvas
  void _carregarFotosEvolucao() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('evolucao_corporal').doc('fotos_perfil').get();
    
    if (doc.exists && doc.data() != null) {
      final dados = doc.data()!;
      setState(() {
        _photoUrlAntes = dados['url_antes'];
        _dataAntes = dados['data_antes'];
        _photoUrlDepois = dados['url_depois'];
        _dataDepois = dados['data_depois'];
      });
    }
  }

  // 🔥 CORE FUNCTION: Tira a foto, sobe pro Firebase Storage e salva o link no Firestore
  void _capturarESalvarFoto(String tipo) async {
    if (_enviandoFoto) return;
    
    // Abre a câmera do celular de verdade! 📸
    final XFile? fotoCapturada = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    
    if (fotoCapturada == null) return;

    setState(() => _enviandoFoto = true);
    final dataHoje = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    try {
      // 1. Envia o arquivo binário pesado pro Firebase Storage
      final refStorage = FirebaseStorage.instance
          .ref()
          .child('usuarios/$_userId/evolucao/$tipo.jpg');
      
      final uploadTask = await refStorage.putFile(File(fotoCapturada.path));
      
      // 2. Pega o link gerado pelo Storage
      final urlGerada = await uploadTask.ref.getDownloadURL();

      // 3. Salva o link leve no Firestore (no prontuário do paciente)
      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).collection('evolucao_corporal').doc('fotos_perfil').set({
        'url_$tipo': urlGerada,
        'data_$tipo': dataHoje,
        'timestamp_$tipo': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      setState(() {
        if (tipo == 'antes') {
          _photoUrlAntes = urlGerada;
          _dataAntes = dataHoje;
        } else {
          _photoUrlDepois = urlGerada;
          _dataDepois = dataHoje;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de evolução salva! 💪'), backgroundColor: AppColors.primarySage));
      }
    } catch (e) {
      debugPrint('Erro ao salvar foto de evolução: $e');
    } finally {
      setState(() => _enviandoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Galeria de Evolução Corpoal'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: _enviandoFoto
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(color: AppColors.primarySage), SizedBox(height: 16), Text('Enviando foto segura para a nuvem...', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold))],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Antes e Depois ⚖️', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text('A balança não conta a história toda. Mantenha seu histórico visual atualizado para avaliar a queima de gordura e ganho de massa.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 32),

                  // BLOCO DO ANTES
                  _construirMolduraFoto(titulo: 'Foto Inicial (Antes)', photoUrl: _photoUrlAntes, data: _dataAntes, onTap: () => _capturarESalvarFoto('antes')),
                  
                  const SizedBox(height: 24),
                  const Center(child: Icon(Icons.compare_arrows_rounded, size: 40, color: AppColors.accentPeach)),
                  const SizedBox(height: 24),

                  // BLOCO DO DEPOIS (Pode ser atualizado sempre)
                  _construirMolduraFoto(titulo: 'Foto Atual (Depois)', photoUrl: _photoUrlDepois, data: _dataDepois, onTap: () => _capturarESalvarFoto('depois')),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _construirMolduraFoto({required String titulo, required String? photoUrl, required String? data, required VoidCallback onTap}) {
    final hasPhoto = photoUrl != null;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15)),
                if (hasPhoto) Text(data ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.backgroundCreme.withOpacity(0.5),
                image: hasPhoto ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
              ),
              child: !hasPhoto
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.primarySage.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('Toque para abrir a câmera', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text('(Frente, Lado ou Costas)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (hasPhoto)
            InkWell(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(color: AppColors.primarySage, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
                child: const Center(child: Text('Atualizar Foto Atual 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
              ),
            ),
        ],
      ),
    );
  }
}
