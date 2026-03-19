import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/ingredient.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool hasNotifiedThisSession = false;

  // Inicializar el servicio
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Pedir permisos 
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Configuración del canal de notificaciones Android
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'pantry_expiry_channel',        // ID del canal
    'Pantry Expiry Alerts',         // Nombre del canal
    channelDescription: 'Alerts for ingredients expiring soon',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF4CAF50),
    playSound: true,
    enableVibration: true,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  int getExpiringCount(List<Ingredient> ingredients) {
    int count = 0;
    for (final ingredient in ingredients) {
      if (ingredient.expirationDate == null) continue;
      final daysLeft = ingredient.daysUntilExpiration ?? 0;
      if (daysLeft <= 7) {
        count++;
      }
    }
    return count;
  }

  void showWelcomeSummary(int expiringCount, int cartCount, List<Ingredient> ingredients) {
    if (hasNotifiedThisSession) return;

    // Solo verificamos ingredientes expirables para las notificaciones de sistema
    if (expiringCount > 0) {
      checkAndNotifyExpiringIngredients(ingredients);
    }

    hasNotifiedThisSession = true;
  }

  // Verificar y enviar notificaciones de ingredientes que expiran pronto
  Future<int> checkAndNotifyExpiringIngredients(
      List<Ingredient> ingredients) async {
    // Cancelar todas las notificaciones anteriores de pantry
    await _plugin.cancelAll();

    int notificationCount = 0;
    int notificationId = 0;

    for (final ingredient in ingredients) {
      if (ingredient.expirationDate == null) continue;

      final daysLeft = ingredient.daysUntilExpiration ?? 0;

      // Notificar si expira en 7 días o menos
      if (daysLeft <= 7 && daysLeft >= 0) {
        String title;
        String body;

        if (daysLeft == 0) {
          title = '⚠️ Expira HOY';
          body = '${ingredient.name} expira hoy. Úsalo pronto.';
        } else if (daysLeft == 1) {
          title = '⚠️ Expira mañana';
          body = '${ingredient.name} expira mañana.';
        } else if (daysLeft <= 3) {
          title = '🔴 Expira pronto';
          body = '${ingredient.name} expira en $daysLeft días.';
        } else {
          title = '🟡 Aviso de expiración';
          body = '${ingredient.name} expira en $daysLeft días.';
        }

        await _plugin.show(
          notificationId++,
          title,
          body,
          _notificationDetails,
        );

        notificationCount++;
      } else if (daysLeft < 0) {
        // Ya expirado
        await _plugin.show(
          notificationId++,
          '🔴 Ingrediente expirado',
          '${ingredient.name} ya expiró hace ${daysLeft.abs()} días.',
          _notificationDetails,
        );
        notificationCount++;
      }
    }

    return notificationCount; // Retorna el total de notificaciones enviadas
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}