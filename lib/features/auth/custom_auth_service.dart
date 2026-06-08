import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String colecaoUsuarios = 'usuarios';

  /// Faz a consulta direta no banco de dados verificando email e senha.
  /// Retorna o ID do usuário (uid) se encontrar, ou nulo se as credenciais forem inválidas.
  Future<String?> realizarLogin(String email, String senha) async {
    try {
      // Faz a busca na coleção de usuários
      final QuerySnapshot resultado = await _db
          .collection(colecaoUsuarios)
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('senha', isEqualTo: senha)
          .limit(1) // Precisamos de apenas 1 correspondência
          .get();

      if (resultado.docs.isNotEmpty) {
        // Encontrou o usuário! Retorna o ID do documento.
        return resultado.docs.first.id;
      } else {
        // Credenciais incorretas ou usuário não existe.
        return null;
      }
    } catch (e) {
      throw Exception('Erro ao consultar o banco de dados: $e');
    }
  }

  /// Registra um novo usuário diretamente na coleção (Simulando um cadastro)
  Future<String> registrarUsuario(String nome, String email, String senha) async {
    try {
      // Cria um novo documento no Firestore e o Firebase gera um ID automático
      final DocumentReference novoDoc = await _db.collection(colecaoUsuarios).add({
        'nome': nome,
        'email': email.trim().toLowerCase(),
        'senha': senha, // Lembrete: em produção, aplique um hash aqui!
        'criado_em': FieldValue.serverTimestamp(),
      });

      return novoDoc.id;
    } catch (e) {
      throw Exception('Erro ao registrar usuário: $e');
    }
  }
}
