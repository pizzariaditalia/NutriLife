import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _alarmeAgua = false;
  bool _alarmeRefeicoes = false;

  void _alternarAlarmesAgua(bool valor) async {
    setState(() => _alarmeAgua = valor);
    if (valor) {
      // Agenda disparos automáticos locais todos os dias de hora em hora (simulado por IDs)
      await NotificationService.agendarAlarmeDiario(id: 10, titulo: 'Hora de beber água! 💧', corpo: 'Mantenha o seu metabolismo ativo. Vá buscar 250ml agora.', hora: 10, minuto: 0);
      await NotificationService.agendarAlarmeDiario(id: 14, titulo: 'Beba Água! 🌊', corpo: 'Já completou metade da sua meta de hoje? Beba mais um copo.', hora: 14, minuto: 30);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lembretes de Hidratação ativos! 💧'), backgroundColor: AppColors.primarySage));
    } else {
      await NotificationService.cancelarTodosOsAlarmes(); // Zera o chip
      setState(() => _alarmeRefeicoes = false);
    }
  }

  void _alternarAlarmesRefeicoes(bool valor) async {
    setState(() => _alarmeRefeicoes = valor);
    if (valor) {
      await NotificationService.agendarAlarmeDiario(id: 8, titulo: 'Café da Manhã Prescrito ☕', corpo: 'Abra o seu diário para registrar a sua primeira refeição do dia.', hora: 8, minuto: 0);
      await NotificationService.agendarAlarmeDiario(id: 16, titulo: 'Lanche da Tarde 🍌', corpo: 'Não pule o lanche para não quebrar o seu défice calórico. Hora de comer!', hora: 16, minuto: 15);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alertas de Refeições agendados! 🍎'), backgroundColor: AppColors.primarySage));
    } else {
      await NotificationService.cancelarTodosOsAlarmes();
      setState(() => _alarmeAgua = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCreme,
      appBar: AppBar(
        title: const Text('Lembretes e Hábitos'),
        backgroundColor: AppColors.primarySage,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Alertas Automáticos 🔔', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('Configure os despertadores internos para blindar a sua rotina e não esquecer os horários clínicos.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 32),

          // CARD ÁGUA
          Card(
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SwitchListTile(
              title: const Text('Lembrete de Hidratação', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              subtitle: const Text('Disparar alertas periódicos para ingestão de água.', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.primarySage,
              secondary: const CircleAvatar(backgroundColor: Colors.blueIndexed == null ? Color(0xFFE3F2FD) : Color(0xFFE3F2FD), child: Icon(Icons.water_drop, color: Colors.blue)),
              value: _alarmeAgua,
              onChanged: _alternarAlarmesAgua,
            ),
          ),
          const SizedBox(height: 12),

          // CARD REFEIÇÕES
          Card(
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SwitchListTile(
              title: const Text('Horários das Refeições', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              subtitle: const Text('Avisar quando for o momento de comer as metas da Nutri.', style: TextStyle(fontSize: 12)),
              activeColor: AppColors.primarySage,
              secondary: CircleAvatar(backgroundColor: AppColors.accentPeach.withOpacity(0.15), child: const Icon(Icons.restaurant, color: AppColors.accentPeach)),
              value: _alarmeRefeicoes,
              onChanged: _alternarAlarmesRefeicoes,
            ),
          ),
        ],
      ),
    );
  }
}