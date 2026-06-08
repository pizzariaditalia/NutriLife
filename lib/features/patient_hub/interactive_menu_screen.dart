import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'smart_swaps_screen.dart'; // Importando a tela de trocas inteligentes

// Modelos de dados para o cardápio
class ItemCardapio {
  final String nome;
  final String porcao;
  final int calorias;
  bool consumido;
  final bool permiteTroca;

  ItemCardapio({
    required this.nome,
    required this.porcao,
    required this.calorias,
    this.consumido = false,
    this.permiteTroca = false,
  });
}

class Refeicao {
  final String titulo;
  final String horario;
  final List<ItemCardapio> itens;

  Refeicao({
    required this.titulo,
    required this.horario,
    required this.itens,
  });
}

class InteractiveMenuScreen extends StatefulWidget {
  const InteractiveMenuScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveMenuScreen> createState() => _InteractiveMenuScreenState();
}

class _InteractiveMenuScreenState extends State<InteractiveMenuScreen> {
  // Simulando o cardápio prescrito pela nutricionista offline
  final List<Refeicao> _cardapioDiario = [
    Refeicao(
      titulo: 'Café da Manhã',
      horario: '08:00',
      itens: [
        ItemCardapio(nome: 'Pão Francês', porcao: '1 unidade (50g)', calorias: 150, permiteTroca: true),
        ItemCardapio(nome: 'Ovo Mexido', porcao: '2 unidades', calorias: 180),
        ItemCardapio(nome: 'Café sem açúcar', porcao: '1 xícara (200ml)', calorias: 5),
      ],
    ),
    Refeicao(
      titulo: 'Almoço',
      horario: '13:00',
      itens: [
        ItemCardapio(nome: 'Arroz Integral', porcao: '3 colheres de sopa', calorias: 120, permiteTroca: true),
        ItemCardapio(nome: 'Feijão Carioca', porcao: '1 concha média', calorias: 90),
        ItemCardapio(nome: 'Frango Grelhado', porcao: '1 filé médio (100g)', calorias: 165),
        ItemCardapio(nome: 'Salada de Folhas', porcao: 'À vontade', calorias: 15),
      ],
    ),
  ];

  void _alternarConsumo(ItemCardapio item, bool? valor) {
    setState(() {
      item.consumido = valor ?? false;
    });

    if (item.consumido) {
      // Micro-animação de recompensa positiva ao marcar como consumido
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Muito bem! ${item.nome} registrado. 🎉'),
            ],
          ),
          backgroundColor: AppColors.secondaryMenta,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _abrirTrocaInteligente(ItemCardapio item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SmartSwapsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Meu Cardápio'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _cardapioDiario.length,
          itemBuilder: (context, index) {
            final refeicao = _cardapioDiario[index];
            return _buildCardRefeicao(refeicao);
          },
        ),
      ),
    );
  }

  Widget _buildCardRefeicao(Refeicao refeicao) {
    // Calcula o total de calorias da refeição
    int totalCalorias = refeicao.itens.fold(0, (soma, item) => soma + item.calorias);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da Refeição
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryMenta.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.primarySage),
                    const SizedBox(width: 8),
                    Text(
                      refeicao.horario,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      refeicao.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$totalCalorias kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySage,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de Alimentos
          ...refeicao.itens.map((item) => _buildItemAlimento(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItemAlimento(ItemCardapio item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: item.consumido,
          onChanged: (valor) => _alternarConsumo(item, valor),
          activeColor: AppColors.secondaryMenta,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.nome,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: item.consumido ? Colors.grey : AppColors.textDark,
            decoration: item.consumido ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${item.porcao} • ${item.calorias} kcal',
          style: TextStyle(
            color: item.consumido ? Colors.grey : Colors.grey.shade700,
            decoration: item.consumido ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: item.permiteTroca && !item.consumido
            ? IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.accentPeach),
                tooltip: 'Encontrar substituto',
                onPressed: () => _abrirTrocaInteligente(item),
              )
            : null,
      ),
    );
  }
}
