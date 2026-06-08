import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Modelo para os itens da lista
class InsumoCompra {
  final String nome;
  final String quantidade;
  bool comprado;

  InsumoCompra({
    required this.nome,
    required this.quantidade,
    this.comprado = false,
  });
}

// Modelo para agrupar os itens por setor do supermercado
class SetorMercado {
  final String titulo;
  final IconData icone;
  final List<InsumoCompra> insumos;

  SetorMercado({
    required this.titulo,
    required this.icone,
    required this.insumos,
  });
}

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({Key? key}) : super(key: key);

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  // Simulação da compilação automática baseada no cardápio da semana
  final List<SetorMercado> _listaSemanal = [
    SetorMercado(
      titulo: 'Hortifruti',
      icone: Icons.local_florist_rounded,
      insumos: [
        InsumoCompra(nome: 'Batata Doce', quantidade: '1.5 kg'),
        InsumoCompra(nome: 'Folhas Verdes (Alface, Rúcula)', quantidade: '3 maços'),
        InsumoCompra(nome: 'Tomate', quantidade: '1 kg'),
        InsumoCompra(nome: 'Limão', quantidade: '1 dúzia'),
      ],
    ),
    SetorMercado(
      titulo: 'Açougue & Ovos',
      icone: Icons.set_meal_rounded,
      insumos: [
        InsumoCompra(nome: 'Peito de Frango', quantidade: '2 kg'),
        InsumoCompra(nome: 'Ovos Brancos', quantidade: '2 cartelas (60 un)'),
        InsumoCompra(nome: 'Patinho Moído', quantidade: '1 kg'),
      ],
    ),
    SetorMercado(
      titulo: 'Mercearia & Grãos',
      icone: Icons.shopping_basket_rounded,
      insumos: [
        InsumoCompra(nome: 'Arroz Integral', quantidade: '1 pacote (1kg)'),
        InsumoCompra(nome: 'Goma de Tapioca', quantidade: '2 pacotes (1kg)'),
        InsumoCompra(nome: 'Azeite Extra Virgem', quantidade: '1 garrafa (500ml)'),
        InsumoCompra(nome: 'Aveia em Flocos', quantidade: '500g'),
      ],
    ),
  ];

  void _alternarCompra(InsumoCompra insumo, bool? valor) {
    setState(() {
      insumo.comprado = valor ?? false;
    });
  }

  // Calcula o progresso total da compra
  double get _progressoTotal {
    int totalInsumos = 0;
    int comprados = 0;

    for (var setor in _listaSemanal) {
      totalInsumos += setor.insumos.length;
      comprados += setor.insumos.where((i) => i.comprado).length;
    }

    return totalInsumos == 0 ? 0 : comprados / totalInsumos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Progresso Superior
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primarySage,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primarySage.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progresso do Carrinho',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_progressoTotal * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppColors.secondaryMenta,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressoTotal,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: AppColors.secondaryMenta,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tudo organizado para a sua semana saudável!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Lista de Setores
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _listaSemanal.length,
                itemBuilder: (context, index) {
                  final setor = _listaSemanal[index];
                  return _buildCardSetor(setor);
                },
              ),
            ),
          ],
        ),
      ),
      // Botão Flutuante para limpar a lista ou finalizar
      floatingActionButton: _progressoTotal == 1.0
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compras finalizadas! Despensa abastecida! 🥦'),
                    backgroundColor: AppColors.secondaryMenta,
                  ),
                );
              },
              backgroundColor: AppColors.primarySage,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Finalizar', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildCardSetor(SetorMercado setor) {
    // Verifica quantos itens daquele setor já foram comprados
    int compradosNoSetor = setor.insumos.where((i) => i.comprado).length;
    bool setorCompleto = compradosNoSetor == setor.insumos.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: !setorCompleto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconColor: AppColors.primarySage,
        collapsedIconColor: Colors.grey,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: setorCompleto ? AppColors.secondaryMenta.withOpacity(0.2) : AppColors.backgroundCreme,
            shape: BoxShape.circle,
          ),
          child: Icon(
            setorCompleto ? Icons.check_circle : setor.icone,
            color: setorCompleto ? AppColors.secondaryMenta : AppColors.primarySage,
          ),
        ),
        title: Text(
          setor.titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: setorCompleto ? Colors.grey : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '$compradosNoSetor de ${setor.insumos.length} itens',
          style: TextStyle(
            color: setorCompleto ? Colors.grey : AppColors.accentPeach,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: setor.insumos.map((insumo) => _buildItemCompra(insumo)).toList(),
      ),
    );
  }

  Widget _buildItemCompra(InsumoCompra insumo) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: CheckboxListTile(
        value: insumo.comprado,
        onChanged: (valor) => _alternarCompra(insumo, valor),
        activeColor: AppColors.secondaryMenta,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          insumo.nome,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: insumo.comprado ? Colors.grey : AppColors.textDark,
            decoration: insumo.comprado ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          insumo.quantidade,
          style: TextStyle(
            fontSize: 13,
            color: insumo.comprado ? Colors.grey : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
