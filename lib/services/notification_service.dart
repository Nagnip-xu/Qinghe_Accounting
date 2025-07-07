import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; // 导入navigatorKey

class NotificationService {
  static const String _notificationEnabledKey = 'notification_enabled';

  // 单例模式
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _hasPermission = false;

  // 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化时区数据
      tz_data.initializeTimeZones();

      // 初始化通知插件
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // 处理通知点击
          print('通知被点击: ${details.payload}');
          // 这里可以添加导航到特定页面的逻辑
        },
      );

      // 检查通知权限状态
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_notificationEnabledKey) ?? true;

      // 检查实际的通知权限
      if (enabled) {
        _hasPermission = await _checkRealPermission();
      } else {
        _hasPermission = false;
      }

      _isInitialized = true;
      print('通知服务初始化成功，通知权限: $_hasPermission');
    } catch (e) {
      print('通知服务初始化失败: $e');
      _isInitialized = false;
    }
  }

  // 检查实际的通知权限
  Future<bool> _checkRealPermission() async {
    try {
      if (Theme.of(navigatorKey.currentContext!).platform ==
          TargetPlatform.iOS) {
        final result = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      } else {
        // Android 13及以上需要请求POST_NOTIFICATIONS权限
        return await Permission.notification.isGranted;
      }
    } catch (e) {
      print('检查通知权限失败: $e');
      return false;
    }
  }

  // 检查通知是否启用
  Future<bool> isNotificationEnabled() async {
    if (!_isInitialized) await initialize();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  // 设置通知是否启用
  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
    _hasPermission = enabled && await _checkRealPermission();
  }

  // 检查是否有通知权限
  Future<bool> hasPermission() async {
    if (!_isInitialized) await initialize();
    return _hasPermission;
  }

  // 请求通知权限
  Future<bool> requestPermission() async {
    if (!_isInitialized) await initialize();

    try {
      bool permissionGranted = false;

      // iOS请求权限
      if (Theme.of(navigatorKey.currentContext!).platform ==
          TargetPlatform.iOS) {
        permissionGranted =
            await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      } else {
        // Android权限
        // 对于Android 13+，使用permission_handler请求POST_NOTIFICATIONS权限
        final status = await Permission.notification.request();
        permissionGranted = status.isGranted;
        
        // 如果用户拒绝但未永久拒绝，提示用户在设置中开启
        if (status.isDenied && !status.isPermanentlyDenied) {
          print('用户拒绝了通知权限，但未永久拒绝');
        }
        
        // 如果用户永久拒绝，需要引导用户去设置中手动开启
        if (status.isPermanentlyDenied) {
          print('用户永久拒绝了通知权限，需要引导用户去设置中手动开启');
        }
      }

      // 保存设置
      if (permissionGranted) {
        await setNotificationEnabled(true);
      }

      _hasPermission = permissionGranted;
      return permissionGranted;
    } catch (e) {
      print('请求通知权限失败: $e');
      return false;
    }
  }

  // 发送通知
  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    // 重新检查权限，确保有最新的权限状态
    _hasPermission = await _checkRealPermission();
    
    if (!_hasPermission) {
      print('无通知权限，无法安排通知');
      return -1;
    }

    try {
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      // 创建通知详情
      final androidDetails = AndroidNotificationDetails(
        'bill_reminders_channel',
        '账单提醒',
        channelDescription: '账单到期通知',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const DefaultStyleInformation(true, true),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 获取时区相关信息
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // 安排通知 - 修复参数问题
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payload,
      );

      print('成功安排通知: ID=$notificationId, 时间=$scheduledDate');
      return notificationId;
    } catch (e) {
      print('安排通知失败: $e');
      return -1;
    }
  }

  // 取消通知
  Future<bool> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();

    try {
      await _notificationsPlugin.cancel(id);
      print('成功取消通知: ID=$id');
      return true;
    } catch (e) {
      print('取消通知失败: $e');
      return false;
    }
  }

  // 恢复保存的提醒
  Future<void> restoreReminders() async {
    if (!_isInitialized) await initialize();
    
    // 重新检查权限
    _hasPermission = await _checkRealPermission();
    
    if (!_hasPermission) {
      print('无通知权限，无法恢复提醒');
      return;
    }

    // 数据库中读取提醒设置通过ReminderProvider完成
    print('恢复保存的提醒设置');
  }

  // 请求通知权限
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      
      // 同时使用permission_handler请求权限，确保Android 13+能够正常工作
      await Permission.notification.request();
    }
  }

  // 发送预算即将超出的通知
  Future<void> showBudgetApproachingLimitNotification({
    required String categoryName,
    required double percentage,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_hasPermission) return;

    try {
      final int notificationId = 
          DateTime.now().millisecondsSinceEpoch % 100000 + 1000;

      final androidDetails = AndroidNotificationDetails(
        'budget_alerts_channel',
        '预算提醒',
        channelDescription: '预算接近或超出限制的提醒',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        notificationId,
        '预算提醒',
        '您的$categoryName类别预算已使用${percentage.toStringAsFixed(1)}%',
        notificationDetails,
      );
    } catch (e) {
      print('发送预算提醒通知失败: $e');
    }
  }

  // 发送预算已超出的通知
  Future<void> showBudgetExceededNotification({
    required String categoryName,
    required double percentage,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'budget_alerts_channel',
          '预算提醒',
          channelDescription: '预算接近或超出限额时的提醒',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      2, // ID为2的通知，表示预算已超出
      '预算超支警告',
      '$categoryName 预算已使用 ${percentage.toStringAsFixed(1)}%，已超出预算',
      platformChannelSpecifics,
    );
  }

  // 发送总预算相关通知
  Future<void> showTotalBudgetNotification({
    required bool isExceeded,
    required double percentage,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'budget_alerts_channel',
          '预算提醒',
          channelDescription: '预算接近或超出限额时的提醒',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final String title = isExceeded ? '月度总预算超支警告' : '月度总预算提醒';
    final String body =
        isExceeded
            ? '本月总预算已使用 ${percentage.toStringAsFixed(1)}%，已超出预算！'
            : '本月总预算已使用 ${percentage.toStringAsFixed(1)}%，即将超出预算';

    await _notificationsPlugin.show(
      3, // ID为3的通知，表示总预算
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
