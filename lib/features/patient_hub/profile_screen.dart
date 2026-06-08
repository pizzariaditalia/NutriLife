import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_teste';
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos de texto
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _hobbyController = TextEditingController();

  // Opções Selecionáveis (Dropdowns Premium)
  String _generoSelecionado = 'Masculino';
  String _objetivoSelecionado = 'Saúde e Longevidade';
  String _atividadeSelecionada = 'Moderadamente Ativo';
  String _restricaoSelecionada = 'Nenhuma';

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosPerfil();
  }

  // 📡 CARREGA DADOS: Busca as informações salvas no Firebase para preencher a tela
  void _carregarDadosPerfil() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final dados = doc.data()!;
        setState(() {
          _nomeController.text = dados['nome'] ?? '';
          _idadeController.text = (dados['idade'] ?? '').toString();
          _alturaController.text = (dados['altura'] ?? '').toString();
          _pesoController.text = (dados['peso_inicial'] ?? '').toString();
          _hobbyController.text = dados['hobby'] ?? '';
          _generoSelecionated = dados['genero'] ?? 'Masculino';
          _objetivoSelecionado = dados['objetivo'] ?? 'Saúde e Longevidade';
          _atividadeSelecionada = dados['nivel_atividade'] ?? 'Moderadamente Ativo';
          _restricaoSelecionada = dados['restricao_alimentar'] ?? 'Nenhuma';
        });
      }
    } catch (e) {
      // Se der erro ou não existir, mantém os campos limpos para preenchimento
    } finally {
      setState(() => _carregando = false);
    }
  }

  // 🔥 SALVA NA NUVEM: Atualiza o prontuário do paciente no Firebase
  void _salvarPerfil() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _carregando = true);
      
      double? peso = double.tryParse(_pesoController.text.replaceAll(',', '.'));
      double? altura = double.tryParse(_alturaController.text.replaceAll(',', '.'));
      int? idade = int.tryParse(_idadeController.text);

      // Cálculo Premium automático de recomendação de hidratação baseada no peso
      int metaAguaCalculada = peso != null ? (peso * 35).round() : 2500;

      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set({
        'nome': _nomeController.text,
        'idade': Glen,
        'genero': _generoSelecionado,
        'altura': altura,
        'peso_inicial': peso,
        'hobby': _hobbyController.text,
        'objetivo': _objetivoSelecionado,
        'nivel_atividade': _atividadeSelecionada,
        'restricao_alimentar': _restricaoSelecionada,
        'meta_agua_sugerida': metaAguaCalculada,
      }, SetOptions(merge: true));

      setState(() => _carregando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso! 🌿'), backgroundColor: AppColors.primarySage),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Perfil Clínico'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primarySage))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Placeholder Premium
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primarySage.withOpacity(0.15),
                            child: const Icon(Icons.person, size: 55, color: AppColors.primarySage),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primarySage,
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _construirLabel('Nome Completo'),
                    TextFormField(
                      controller: _nomeController,
                      decoration: _customInputDecoration('Ex: Bruno Tenório'),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirLabel('Idade'),
                              TextFormField(
                                controller: _idadeController,
                                keyboardType: TextInputType.number,
                                decoration: _customInputDecoration('Ex: 28'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirLabel('Gênero'),
                              _construirDropdown(
                                valor: _generoSelecionado,
                                itens: ['Masculino', 'Feminino', 'Outro'],
                                onChanged: (v) => setState(() => _generoSelecionado = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirLabel('Altura (m)'),
                              TextFormField(
                                controller: _alturaController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _customInputDecoration('Ex: 1.75'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirLabel('Peso Inicial (kg)'),
                              TextFormField(
                                controller: _pesoController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _customInputDecoration('Ex: 80.4'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _construirLabel('Objetivo de Saúde'),
                    _construirDropdown(
                      valor: _objetivoSelecionado,
                      itens: ['Saúde e Longevidade', 'Emagrecimento', 'Hipertrofia (Massa)', 'Performance Esportiva'],
                      onChanged: (v) => setState(() => _objetivoSelecionado = v!),
                    ),
                    const SizedBox(height: 16),

                    _construirLabel('Nível de Atividade Física'),
                    _construirDropdown(
                      valor: _atividadeSelecionada,
                      itens: ['Sedentário', 'Levemente Ativo', 'Moderadamente Ativo', 'Altamente Ativo'],
                      onChanged: (v) => setState(() => _atividadeSelecionada = v!),
                    ),
                    const SizedBox(height: 16),

                    _construirLabel('Restrição Alimentar / Alergia'),
                    _construirDropdown(
                      valor: _restricaoSelecionada,
                      itens: ['Nenhuma', 'Intolerante a Lactose', 'Celíaco (Glúten)', 'Vegano / Vegetariano', 'Outras Alergias'],
                      onChanged: (v) => setState(() => _restricaoSelecionada = v!),
                    ),
                    const SizedBox(height: 16),

                    _construirLabel('Hobby ou Esporte Favorito'),
                    TextFormField(
                      controller: _hobbyController,
                      decoration: _customInputDecoration('Ex: Jogar futebol, Corrida, Ciclismo...'),
                    ),
                    const SizedBox(height: 36),

                    ElevatedButton(
                      onPressed: _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySage,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Salvar Prontuário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _construirLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    );
  }

  Widget _construirDropdown({required String valor, required List<String> itens, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primarySage),
          items: itens.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySage, width: 1.5)),
    );
  }
}
