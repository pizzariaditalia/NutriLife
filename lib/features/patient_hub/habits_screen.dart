import 'package:flutter/material.dart';
import 'package:nutri_life/core/theme/app_colors.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // 🚀 EXPANDIDO: Banco de dados local com 7 lembretes essenciais de rotina
  final List<Map<String, dynamic>> _lembretes = [
    {'titulo': 'Desjejum Saudável 🍳', 'horario': '07:30', 'ativado': true, 'categoria': 'Refeição'},
    {'titulo': 'Meta de Hidratação 💧', 'horario': '09:30', 'ativado': true, 'categoria': 'Água'},
    {'titulo': 'Almoço Balanceado 🥗', 'horario': '12:30', 'ativado': false, 'categoria': 'Refeição'},
    {'titulo': 'Lanche de Performance 🍌', 'horario': '16:00', 'ativado': true, 'categoria': 'Refeição'},
    {'titulo': 'Hora do Treino Diário 🏃‍♂️', 'horario': '18:30', 'ativado': false, 'categoria': 'Treino'},
    {'titulo': 'Jantar Leve 🍗', 'horario': '20:30', 'ativado': false, 'categoria': 'Refeição'},
    {'titulo': 'Desconexão e Higiene do Sono 😴', 'horario': '22:30', 'ativado': true, 'categoria': 'Descanso'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Minha Rotina Diária', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Lembretes e Hábitos 🕒', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text('Configure seus alarmes internos para não esquecer nenhuma etapa do seu plano estratégico.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 24),

          ..._lembretes.map((alarme) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: alarme['ativado'] ? AppColors.primarySage.withOpacity(0.1) : Colors.grey.shade100,
                        child: Icon(
                          alarme['categoria'] == 'Água' ? Icons.water_drop : (alarme['categoria'] == 'Treino' ? Icons.fitness_center : Icons.alarm),
                          color: alarme['ativado'] ? AppColors.primarySage : Colors.grey, size: 20
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alarme['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          Text('Disparar às ${alarme['horario']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: alarme['ativado'],
                    activeColor: AppColors.primarySage,
                    onChanged: (bool valor) {
                      setState(() {
                        alarme['ativado'] = valor;
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
