import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MealDiaryScreen extends StatefulWidget {
  const MealDiaryScreen({Key? key}) : super(key: key);

  @override
  State<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends State<MealDiaryScreen> {
  int _diaSelecionadoIndex = 2; // Começa no "Hoje"
  
  // Lista fictícia de dias para o topo do calendário horizontal premium
  final List<Map<String, String>> _linhaDoTempoDias = [
    {'semana': 'QUA', 'numero': '03'},
    {'semana': 'QUI', 'numero': '04'},
    {'semana': 'SEX', 'numero': '05'},
    {'semana': 'SÁB', 'numero': '06'},
    {'semana': 'DOM', 'numero': '07'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Diário Alimentar'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. SELETOR DE DATA PREMIUM (ESTILO TIMELINE CALENDAR)
          Container(
            color: AppColors.primarySage,
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _linhaDoTempoDias.length,
                itemBuilder: (context, index) {
                  final item = _linhaDoTempoDias[index];
                  bool isSelecionado = index == _diaSelecionadoIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _diaSelecionadoIndex = index;
                      });
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelecionado ? Colors.white : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['semana']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelecionado ? AppColors.primarySage : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['numero']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelecionado ? AppColors.textDark : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. LISTA DE REFEIÇÕES POR TURNOS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ConstruirBlocoRefeicao(
                  titulo: 'Café da Manhã',
                  subtitulo: 'Recomendado: 400 - 500 kcal',
                  caloriasConsumidas: 342,
                  icone: Icons.wb_twilight_rounded,
                  corIcone: Colors.amber,
                  alimentos: [
                    _ItemAlimentoFicticio(nome: 'Pão Integral', detalhe: '2 fatias (50g)', kcal: 122),
                    _ItemAlimentoFicticio(nome: 'Ovo Mexido', detalhe: '2 unidades', kcal: 140),
                    _ItemAlimentoFicticio(nome: 'Café com Leite Desnatado', detalhe: '200ml', kcal: 80),
                  ],
                ),
                const SizedBox(height: 16),
                _ConstruirBlocoRefeicao(
                  titulo: 'Almoço',
                  subtitulo: 'Recomendado: 600 - 800 kcal',
                  caloriasConsumidas: 585,
                  icone: Icons.wb_sunny_rounded,
                  corIcone: Colors.orange,
                  alimentos: [
                    _ItemAlimentoFicticio(nome: 'Arroz Integral Cozido', detalhe: '150g', kcal: 195),
                    _ItemAlimentoFicticio(nome: 'Feijão Carioca', detalhe: '1 concha (100g)', kcal: 76),
                    _ItemAlimentoFicticio(nome: 'Filé de Frango Grelhado', detalhe: '120g', kcal: 198),
                    _ItemAlimentoFicticio(nome: 'Salada de Alface e Tomate', detalhe: '1 prato cheio', kcal: 35),
                    _ItemAlimentoFicticio(nome: 'Azeite de Oliva Extra Virgem', detalhe: '1 colher de sopa', kcal: 81),
                  ],
                ),
                const SizedBox(height: 16),
                _ConstruirBlocoRefeicao(
                  titulo: 'Lanche da Tarde',
                  subtitulo: 'Recomendado: 200 - 300 kcal',
                  caloriasConsumidas: 0, // Turno vazio para demonstrar estado dinâmico
                  icone: Icons.fastfood_rounded,
                  corIcone: AppColors.accentPeach,
                  alimentos: [],
                ),
                const SizedBox(height: 16),
                _ConstruirBlocoRefeicao(
                  titulo: 'Jantar',
                  subtitulo: 'Recomendado: 400 - 600 kcal',
                  caloriasConsumidas: 0,
                  icone: Icons.nights_stay_rounded,
                  corIcone: Colors.indigo,
                  alimentos: [],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card estrutural de cada turno de refeição
class _ConstruirBlocoRefeicao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int caloriasConsumidas;
  final IconData icone;
  final Color corIcone;
  final List<_ItemAlimentoFicticio> alimentos;

  const _ConstruirBlocoRefeicao({
    required this.titulo,
    required this.subtitulo,
    required this.caloriasConsumidas,
    required this.icone,
    required this.corIcone,
    required this.alimentos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da refeição
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icone, color: corIcone, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$caloriasConsumidas kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySage,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista interna de alimentos consumidos nesse bloco
          if (alimentos.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alimentos.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) => alimentos[index],
            ),

          // Botão de Adicionar Alimento específico deste turno
          InkWell(
            onTap: () {
              // Lógica de navegação direta para a busca com o parâmetro do turno
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySage.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: AppColors.primarySage, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Adicionar Alimento',
                    style: TextStyle(
                      color: AppColors.primarySage,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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

// Widget de linha para cada alimento listado no diário
class _ItemAlimentoFicticio extends StatelessWidget {
  final String nome;
  final String detalhe;
  final int kcal;

  const _ItemAlimentoFicticio({
    required this.nome,
    required this.detalhe,
    required this.kcal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalhe,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '$kcal kcal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
