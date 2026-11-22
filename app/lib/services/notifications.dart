// ═══ notifications.dart · RECORDATORIOS ═══
// Programa una notificación diaria (a las _hour) con las tareas de ese día,
// para los próximos 30 días. Se reprograma cada vez que se guardan datos.
//   _details → canal y estilo de la notificación en Android/iOS.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/library.dart';
import '../state/app_state.dart';

/// Recordatorios locales: una notificación por día con las tareas que tocan,
/// a las 9:00, para los próximos 30 días. Funcionan con la app cerrada.
class Notifications {
  Notifications._();
  static final instance = Notifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  // ✏️ MODIFICAR: hora del aviso diario, hora límite de la noche y días a futuro.
  static const _hour = 9, _quietAfter = 21, _daysAhead = 30;

  bool _ready = false;
  Timer? _debounce;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'cuidados',
      'Recordatorios de cuidados',
      channelDescription: 'Avisos para regar, abonar y cuidar tus plantas',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('Zona horaria no disponible, uso UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Pide permiso al usuario. Devuelve true si quedó concedido.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  void reschedule(AppState state) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _reschedule(state));
  }

  Future<void> _reschedule(AppState state) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final tasks = state.allTasks();
      final now = tz.TZDateTime.now(tz.local);

      for (var day = 0; day <= _daysAhead; day++) {
        // Día 0 incluye las tareas atrasadas.
        final items = tasks.where((t) => day == 0 ? t.due <= 0 : t.due == day).toList();
        if (items.isEmpty) continue;

        var when = tz.TZDateTime(tz.local, now.year, now.month, now.day + day, _hour);
        if (when.isBefore(now)) {
          if (day != 0) continue;
          when = now.add(const Duration(minutes: 1)); // hoy ya pasó la hora del aviso
          if (now.hour >= _quietAfter) continue; // no molestar de noche
        }

        final water = items.where((t) => t.task == CareTask.water).map((t) => t.plant.name).toList();
        final others = items.where((t) => t.task != CareTask.water).toList();
        // ✏️ MODIFICAR: texto del aviso.
        final parts = <String>[
          if (water.isNotEmpty) 'Regar: ${water.join(', ')}',
          ...others.take(3).map((t) => '${t.task.label}: ${t.plant.name}'),
        ];

        await _plugin.zonedSchedule(
          id: day,
          title: water.isNotEmpty ? '💧 Tus plantas tienen sed' : '🌿 Cuidados de hoy',
          body: parts.join(' · '),
          scheduledDate: when,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Error programando notificaciones: $e');
    }
  }
}
