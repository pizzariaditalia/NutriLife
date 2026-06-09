import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // 🔌 INICIALIZAÇÃO: Configura o suporte de alertas no Android
  static Future<void> inicializar() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(initializationSettings);
  }

  // ⏰ AGENDA LEMBRETE DIÁRIO RECORRENTE
  static Future<void> agendarAlarmeDiario({
    required int id,
    required String titulo,
    required String corpo,
    required int hora,
    required int minuto,
  }) async {
    // Nota: Como o robô compila em release pura, usamos o canal padrão atómico do Android
    await _plugin.showDailyAtTime(
      id,
      titulo,
      corpo,
      Time(hora, minuto, 0),
      const AndroidNotificationDetails(
        'nutrilife_reminders',
        'Lembretes Nutri Life',
        channelDescription: 'Alarmes de dieta e hidratação do paciente',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );
  }

  // ❌ CANCELA TODOS OS ALARMES
  static Future<void> cancelarTodosOsAlarmes() async {
    await _plugin.cancelAll();
  }
}
