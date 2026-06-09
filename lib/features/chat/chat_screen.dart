import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutri_life/core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final TextEditingController _mensagemCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  void _enviarMensagem() async {
    if (_mensagemCtrl.text.trim().isEmpty) return;

    String texto = _mensagemCtrl.text.trim();
    _mensagemCtrl.clear();

    // Salva a mensagem na sala exclusiva deste paciente
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_userId)
        .collection('mensagens')
        .add({
      'texto': texto,
      'remetente': 'paciente',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Rola para a última mensagem enviada
    _focarNoFim();
  }

  void _focarNoFim() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Falar com Minha Nutri', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // CANAL DE MENSAGENS EM TEMPO REAL
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_userId)
                  .collection('mensagens')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primarySage));
                }

                final mensagens = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) => _focarNoFim());

                if (mensagens.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Envie uma mensagem para iniciar o chat!', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final dados = mensagens[index].data() as Map<String, dynamic>;
                    bool souEu = dados['remetente'] == 'paciente';

                    return Align(
                      alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: souEu ? AppColors.primarySage : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: souEu ? const Radius.circular(16) : Radius.zero,
                            bottomRight: souEu ? Radius.zero : const Radius.circular(16),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        ),
                        child: Text(
                          dados['texto'] ?? '',
                          style: TextStyle(
                            color: souEu ? Colors.white : AppColors.textDark,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // BARRA DE DIGITAÇÃO
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensagemCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Digite sua dúvida aqui...',
                        filled: true,
                        fillColor: AppColors.backgroundCreme,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _enviarMensagem,
                    backgroundColor: AppColors.primarySage,
                    mini: true,
                    elevation: 0,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
