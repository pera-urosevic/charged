import 'dart:async';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:charged/defaults.dart';
import 'package:charged/log.dart';
import 'package:charged/util.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notificationId = 242;
const notificationChannelId = 'charge_notification_channel';
const notificationChannelTitle = 'Charged Service';
const notificationChannelDescription = 'This channel is used to send battery charge notifications.';
const notificationChannelImportance = Importance.low;

Future<void> initializeService() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationChannelTitle,
    description: notificationChannelDescription,
    importance: notificationChannelImportance,
    enableVibration: true,
    enableLights: true,
    playSound: true,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true,
      foregroundServiceNotificationId: notificationId,
      notificationChannelId: notificationChannelId,
      initialNotificationContent: 'Started Charged service',
      initialNotificationTitle: notificationChannelTitle,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final battery = Battery();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int lowBattery = prefs.getInt('lowBattery') ?? defaultLowBattery;
  int highBattery = prefs.getInt('highBattery') ?? defaultHighBattery;

  void notifyState(String state) {
    flutterLocalNotificationsPlugin.show(
      notificationId,
      notificationChannelTitle,
      'Battery $state',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelTitle,
          icon: 'ic_bg_service_small',
          enableVibration: true,
          enableLights: true,
          playSound: true,
          fullScreenIntent: true,
          importance: Importance.high,
        ),
      ),
    );
  }

  void notifyLevel(String state, int level) {
    flutterLocalNotificationsPlugin.show(
      notificationId,
      notificationChannelTitle,
      'Battery $state: $level%',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationChannelTitle,
          icon: 'ic_bg_service_small',
          enableVibration: true,
          enableLights: true,
          playSound: true,
          fullScreenIntent: true,
          importance: Importance.high,
        ),
      ),
    );
  }

  Future<void> handleBatteryStateChanged(BatteryState state) async {
    final level = await battery.batteryLevel;
    final now = DateTime.now();
    log('[$now] $state = $level, low = $lowBattery, high = $highBattery');
    Map<String, dynamic> payload = {
      'now': formatDateTime(now),
      'state': capitalize(state.name),
      'level': level,
    };
    service.invoke('status update', payload);
    switch (state) {
      case BatteryState.discharging:
        if (level <= lowBattery) {
          notifyLevel('low', level);
        }
        break;
      case BatteryState.charging:
        if (level >= highBattery) {
          notifyLevel('high', level);
        }
        break;
      default:
    }
  }

  service.on('configuration changed').listen((config) {
    log('service on configuration changed $config');
    if (config == null) return;
    if (config.containsKey('lowBattery')) {
      lowBattery = config['lowBattery'];
    }
    if (config.containsKey('highBattery')) {
      highBattery = config['highBattery'];
    }
  });

  service.on('check status').listen((arg) async {
    log('service on status');
    final state = await battery.batteryState;
    notifyState(capitalize(state.name));
  });

  listen() async {
    battery.onBatteryStateChanged.listen(handleBatteryStateChanged);
    log('service listen, low battery = $lowBattery, high battery = $highBattery');
  }

  listen();
}
