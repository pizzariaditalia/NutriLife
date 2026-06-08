import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // Padrão Singleton: Garante que o app inteiro use a mesma instância de conexão
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nomes das Coleções (Tabelas do Banco de Dados)
  static const String colecaoUsuarios = 'usuarios';
  static const String colecaoDiario = 'diario_alimentar';

  // =========================================================================
  // MÓDULO 1: ONBOARDING & PERFIL
  // =========================================================================
  
  /// Salva ou atualiza o perfil e o objetivo escolhido pelo paciente (Emagrecimento, etc.)
  Future<void> salvarObjetivoPaciente(String uid, String objetivo) async {
    try {
      await _db.collection(colecaoUsuarios).doc(uid).set({
        'objetivo_principal': objetivo,
        'atualizado_em': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true evita apagar outros dados do usuário
    } catch (e) {
      throw Exception('Erro ao salvar o objetivo no banco de dados: $e');
    }
  }

  // =========================================================================
  // MÓDULO 3: PAINEL DO PACIENTE & DIÁRIO ALIMENTAR
  // =========================================================================

  /// Registra a quantidade de água consumida no dia. 
  /// O FieldValue.increment faz a soma matemática direto no banco de dados.
  Future<void> registrarConsumoAgua(String uid, String dataAaaaMmDd, int quantidadeAdicionadaMl) async {
    try {
      final docRef = _db
          .collection(colecaoUsuarios)
          .doc(uid)
          .collection(colecaoDiario)
          .doc(dataAaaaMmDd);

      await docRef.set({
        'agua_consumida_ml': FieldValue.increment(quantidadeAdicionadaMl),
        'ultima_atualizacao_agua': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao registrar hidratação: $e');
    }
  }

  /// Salva o score de ansiedade/fome (1 a 5) antes da refeição.
  Future<void> registrarFomeEmocional(String uid, String dataAaaaMmDd, int nivelFome) async {
    try {
      final docRef = _db
          .collection(colecaoUsuarios)
          .doc(uid)
          .collection(colecaoDiario)
          .doc(dataAaaaMmDd);

      await docRef.set({
        'fome_emocional_score': nivelFome,
        'timestamp_fome': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao registrar o rastreador de fome: $e');
    }
  }

  /// Salva um novo alimento consumido e já soma as calorias no total do dia.
  Future<void> adicionarRefeicaoConsumida(String uid, String dataAaaaMmDd, Map<String, dynamic> alimentoMap) async {
    try {
      final docRef = _db
          .collection(colecaoUsuarios)
          .doc(uid)
          .collection(colecaoDiario)
          .doc(dataAaaaMmDd);

      await docRef.set({
        // arrayUnion adiciona o alimento à lista sem duplicar e sem apagar os anteriores
        'alimentos_consumidos': FieldValue.arrayUnion([alimentoMap]),
        // Soma as calorias do alimento recém-adicionado ao total consumido no dia
        'calorias_consumidas': FieldValue.increment(alimentoMap['calorias'] as int),
        'ultima_atualizacao_refeicao': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao adicionar refeição ao diário: $e');
    }
  }

  // =========================================================================
  // BUSCA DE DADOS EM TEMPO REAL (STREAMS)
  // =========================================================================

  /// Cria um "túnel" em tempo real com o Firestore para ouvir mudanças no diário do dia.
  /// Ideal para atualizar o Dashboard instantaneamente.
  Stream<DocumentSnapshot<Map<String, dynamic>>> ouvirDiarioDoDia(String uid, String dataAaaaMmDd) {
    return _db
        .collection(colecaoUsuarios)
        .doc(uid)
        .collection(colecaoDiario)
        .doc(dataAaaaMmDd)
        .snapshots();
  }
}
