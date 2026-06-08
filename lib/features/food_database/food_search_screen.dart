import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Modelo de dados simulando nossa base offline (TACO / IBGE)
class Alimento {
  final String nome;
  final String porcaoBase;
  final int calorias;
  final bool isProcessado;
  final String alertaProcessado;
  final List<String> medidasCaseiras;

  Alimento({
    required this.nome,
    required this.porcaoBase,
    required this.calorias,
    this.isProcessado = false,
    this.alertaProcessado = '',
    required this.medidasCaseiras,
  });
}

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({Key? key}) : super(key: key);

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Banco de dados offline simulado com alimentos brasileiros
  final List<Alimento> _bancoDeAlimentos = [
    Alimento(
      nome: 'Arroz Branco Cozido',
      porcaoBase: '100g',
      calorias: 130,
      medidasCaseiras: ['1 Colher de sopa cheia', '1 Escumadeira média', '1 Xícara'],
    ),
    Alimento(
      nome: 'Feijão Carioca Cozido',
      porcaoBase: '100g',
      calorias: 76,
      medidasCaseiras: ['1 Concha média', '1 Colher de sopa'],
    ),
    Alimento(
      nome: 'Frango Grelhado (Peito)',
      porcaoBase: '100g',
      calorias: 165,
      medidasCaseiras: ['1 Filé médio', '1 Pedaço pequeno', 'Desfiado (1 Colher de sopa)'],
    ),
    Alimento(
      nome: 'Biscoito Recheado de Chocolate',
      porcaoBase: '30g',
      calorias: 140,
      isProcessado: true,
      alertaProcessado: 'Atenção: Alto teor de açúcares escondidos e gordura trans.',
      medidasCaseiras: ['1 Unidade', '1 Pacote inteiro'],
    ),
    Alimento(
      nome: 'Pão Francês',
      porcaoBase: '50g',
      calorias: 150,
      medidasCaseiras: ['1 Unidade (50g)', 'Metade (25g)'],
    ),
  ];

  List<Alimento> _resultados = [];

  @override
  void initState() {
    super.initState();
    _resultados = _bancoDeAlimentos; // Inicia mostrando todos
  }

  void _filtrarAlimentos(String query) {
    setState(() {
      if (query.isEmpty) {
        _resultados = _bancoDeAlimentos;
      } else {
        _resultados = _bancoDeAlimentos
            .where((alimento) =>
                alimento.nome.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _abrirSeletorDePorcao(Alimento alimento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConstruirBottomSheetPorcao(alimento: alimento),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Adicionar Refeição'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Container(
            color: AppColors.primarySage,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarAlimentos,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Buscar na base TACO/IBGE...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: AppColors.primarySage),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filtrarAlimentos('');
                  },
                ),
                filled: true,
                fillColor: AppColors.backgroundCreme,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Lista de Resultados
          Expanded(
            child: _resultados.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum alimento encontrado.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultados.length,
                    itemBuilder: (context, index) {
                      final alimento = _resultados[index];
                      return _ConstruirCardAlimento(
                        alimento: alimento,
                        onTap: () => _abrirSeletorDePorcao(alimento),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget do Card do Alimento para manter o código limpo
class _ConstruirCardAlimento extends StatelessWidget {
  final Alimento alimento;
  final VoidCallback onTap;

  const _ConstruirCardAlimento({
    required this.alimento,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      alimento.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${alimento.calorias} kcal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primarySage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                alimento.porcaoBase,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              if (alimento.isProcessado) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentPeach.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentPeach.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.accentPeach),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alimento.alertaProcessado,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentPeach,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// BottomSheet para escolher as medidas caseiras
class _ConstruirBottomSheetPorcao extends StatefulWidget {
  final Alimento alimento;

  const _ConstruirBottomSheetPorcao({required this.alimento});

  @override
  State<_ConstruirBottomSheetPorcao> createState() =>
      _ConstruirBottomSheetPorcaoState();
}

class _ConstruirBottomSheetPorcaoState
    extends State<_ConstruirBottomSheetPorcao> {
  String? _medidaSelecionada;
  double _quantidade = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.alimento.medidasCaseiras.isNotEmpty) {
      _medidaSelecionada = widget.alimento.medidasCaseiras.first;
    }
  }

  void _salvarNoDiario() {
    // Aqui no futuro salvaremos no Firebase offline
    Navigator.pop(context); // Fecha o BottomSheet
    Navigator.pop(context); // Volta para a tela principal (Dashboard)

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.alimento.nome} adicionado ao diário!'),
        backgroundColor: AppColors.secondaryMenta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCreme,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              align: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.alimento.nome,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primarySage,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Quantidade:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (_quantidade > 0.5) {
                      setState(() => _quantidade -= 0.5);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primarySage,
                  iconSize: 32,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _quantidade.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _quantidade += 0.5);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primarySage,
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Medida Caseira:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _medidaSelecionada,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primarySage),
                  items: widget.alimento.medidasCaseiras.map((String medida) {
                    return DropdownMenuItem<String>(
                      value: medida,
                      child: Text(medida, style: const TextStyle(color: AppColors.textDark)),
                    );
                  }).toList(),
                  onChanged: (String? novaMedida) {
                    setState(() {
                      _medidaSelecionada = novaMedida;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvarNoDiario,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySage,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Adicionar ao Diário',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.backgroundCreme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extensão rápida para consertar o alinhamento do traço no topo do BottomSheet
extension AlignWidget on Widget {
  Widget get align {
    return Align(alignment: Alignment.center, child: this);
  }
}
