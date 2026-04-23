import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Configuração do Android Local
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(), // Adicionado suporte básico iOS
    );

    await _notificationsPlugin.initialize(initSettings);

    // 2. Solicitar permissão para Notificações Push (Android 13+ e iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Inscrever o usuário nos tópicos de Notícias e Agenda
    // Quando você enviar um Push para o tópico "noticias", este usuário receberá
    await _messaging.subscribeToTopic("noticias");
    await _messaging.subscribeToTopic("agenda");

    // 4. Configurar o recebimento em Primeiro Plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          message.notification!.title ?? "Nova atualização",
          message.notification!.body ?? "Confira no app!",
        );
      }
    });
  }

  // Método que você já usava, agora centralizado para Chat e Push
  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'phelifla_general_channel', // Canal único para notícias/agenda/chat
      'Notificações PheliFla',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails generalNotificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID único para não sobrescrever notificações anteriores
      title,
      body,
      generalNotificationDetails,
    );
  }
}