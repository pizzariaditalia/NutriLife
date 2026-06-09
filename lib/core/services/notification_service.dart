import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    // Inicializa os fusos horários exigidos pela v17
    tz.initializeTimeZones(); 

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(initializationSettings);
  }

  static Future<void> agendarAlarmeDiario({
    required int id,
    required String titulo,
    required String corpo,
    required int hora,
    required int minuto,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hora, minuto);
    
    // Se a hora de hoje já passou, agenda para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      titulo,
      corpo,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nutrilife_reminders',
          'Lembretes Nutri Life',
          channelDescription: 'Alarmes de dieta e hidratação do paciente',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      // ✅ AQUI ESTÁ O PARÂMETRO OBRIGATÓRIO QUE FALTAVA
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelarTodosOsAlarmes() async {
    await _plugin.cancelAll();
  }
}
