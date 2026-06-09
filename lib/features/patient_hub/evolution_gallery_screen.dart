import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  String? _pathAntes;
  String? _dataAntes;
  String? _pathDepois;
  String? _dataDepois;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    _carregarFotosEvolucao();
  }

  // 📡 CARREGA CAMINHOS LOCAIS: Pega o texto do endereço do arquivo no Firestore
  void _carregarFotosEvolucao() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userId)
          .collection('evolucao_corporal')
          .doc('fotos_perfil')
          .get();
      
      if (doc.exists && doc.data() != null) {
        final dados = doc.data()!;
        setState(() {
          _pathAntes = dados['path_antes'];
          _dataAntes = dados['data_antes'];
          _pathDepois = dados['path_depois'];
          _dataDepois = dados['data_depois'];
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar caminhos de imagem: $e');
    }
  }

  // 📸 FUNÇÃO ADAPTADA: Abre a câmera, tira a foto e salva o caminho do arquivo no banco
  void _capturarFotoLocal(String tipo) async {
    final XFile? fotoCapturada = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (fotoCapturada == null) return;

    setState(() => _processando = true);
    final dataHoje = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    try {
      // 💾 Salva apenas o caminho textual do arquivo no Cloud Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userId)
          .collection('evolucao_corporal')
          .doc('fotos_perfil')
          .set({
        'path_$tipo': fotoCapturada.path,
        'data_$tipo': dataHoje,
      }, SetOptions(merge: true));

      setState(() {
        if (tipo == 'antes') {
          _pathAntes = fotoCapturada.path;
          _dataAntes = dataHoje;
        } else {
          _pathDepois = fotoCapturada.path;
          _dataDepois = dataHoje;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evolução visual registrada com sucesso! 💪'), backgroundColor: AppColors.primarySage),
        );
      }
    } catch (e) {
      debugPrint('Erro ao registrar imagem: $e');
    } finally {
      setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Galeria de Evolução Corporal'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: _processando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primarySage))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Antes e Depois ⚖️', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text('A balança não conta a história toda. Tire fotos para registrar e comparar sua queima de gordura e ganho de massa de forma 100% gratuita.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 32),

                  // Moldura Antes
                  _construirMolduraFoto(titulo: 'Foto Inicial (Antes)', photoPath: _pathAntes, data: _dataAntes, onTap: () => _capturarFotoLocal('antes')),
                  const SizedBox(height: 24),
                  const Center(child: Icon(Icons.compare_arrows_rounded, size: 40, color: AppColors.accentPeach)),
                  const SizedBox(height: 24),
                  // Moldura Depois
                  _construirMolduraFoto(titulo: 'Foto Atual (Depois)', photoPath: _pathDepois, data: _dataDepois, onTap: () => _capturarFotoLocal('depois')),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _construirMolduraFoto({required String titulo, required String? photoPath, required String? data, required VoidCallback onTap}) {
    // Verifica se a string do caminho existe e se o arquivo físico está presente no celular
    final bool hasPhoto = photoPath != null && File(photoPath).existsSync();
    
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
              ),
              // 🖼️ IMPRIME NA TELA: Puxa o arquivo físico diretamente do armazenamento interno do celular
              child: hasPhoto
                  ? Image.file(File(photoPath), fit: BoxFit.cover, width: double.infinity, height: 300)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.primarySage.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('Toque para abrir a câmera', style: TextStyle(color: AppColors.primarySage, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text('(Frente, Lado ou Costas)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
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
