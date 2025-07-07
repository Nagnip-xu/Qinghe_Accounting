import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

// 账单提醒模型
class BillReminder {
  final int? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool recurring;
  final String? recurringType; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? notificationId;
  final bool completed;

  BillReminder({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.recurring = false,
    this.recurringType,
    this.notificationId,
    this.completed = false,
  });

  // 将数据库记录转换为对象
  factory BillReminder.fromMap(Map<String, dynamic> map) {
    return BillReminder(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['dueDate']),
      recurring: map['recurring'] == 1,
      recurringType: map['recurringType'],
      notificationId: map['notificationId'],
      completed: map['completed'] == 1,
    );
  }

  // 将对象转换为数据库记录
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'recurring': recurring ? 1 : 0,
      'recurringType': recurringType,
      'notificationId': notificationId,
      'completed': completed ? 1 : 0,
    };
  }

  // 创建已更新属性的副本
  BillReminder copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    bool? recurring,
    String? recurringType,
    int? notificationId,
    bool? completed,
  }) {
    return BillReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurring: recurring ?? this.recurring,
      recurringType: recurringType ?? this.recurringType,
      notificationId: notificationId ?? this.notificationId,
      completed: completed ?? this.completed,
    );
  }

  // 获取格式化的到期日期显示
  String get formattedDueDate => DateFormat('yyyy-MM-dd').format(dueDate);

  // 距离到期还有几天
  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;

  // 是否已过期
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !completed;
}

// 账单提醒提供者
class ReminderProvider with ChangeNotifier {
  List<BillReminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  bool _hasPermission = false;

  // 通知服务
  final NotificationService _notificationService = NotificationService();

  List<BillReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermission => _hasPermission;

  // 初始化提醒
  Future<void> initReminders() async {
    _setLoading(true);
    try {
      await _checkPermission();
      await _loadReminders();
      _setError(null);
    } catch (e) {
      _setError('获取账单提醒失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 刷新设置
  Future<void> refreshSettings() async {
    try {
      await _checkPermission();
    } catch (e) {
      _setError('检查通知权限失败：$e');
    }
  }

  // 检查通知权限
  Future<void> _checkPermission() async {
    _hasPermission = await _notificationService.hasPermission();
    notifyListeners();
  }

  // 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      // 先尝试请求通知权限
      _hasPermission = await _notificationService.requestPermission();

      if (_hasPermission) {
        // 权限获取成功，显示成功信息
        print('通知权限获取成功');

        // 立即刷新所有提醒，确保它们能正确显示
        if (_reminders.isNotEmpty) {
          await _refreshAllReminders();
        }
      } else {
        // 权限获取失败，记录日志
        print('用户拒绝了通知权限');
      }

      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _setError('请求通知权限失败：$e');
      return false;
    }
  }

  // 刷新所有提醒的通知
  Future<void> _refreshAllReminders() async {
    print('刷新所有提醒的通知...');

    try {
      // 获取所有未完成的提醒
      final pendingReminders = getPendingReminders();

      for (final reminder in pendingReminders) {
        // 取消原有通知（如果有）
        if (reminder.notificationId != null) {
          await _notificationService.cancelNotification(
            reminder.notificationId!,
          );
        }

        // 重新安排通知
        final notificationId = await _scheduleNotification(reminder);

        // 如果通知ID有变化，更新数据库
        if (notificationId != reminder.notificationId) {
          final updatedReminder = reminder.copyWith(
            notificationId: notificationId,
          );

          final db = await DatabaseHelper.instance.database;
          await db.update(
            'reminders',
            updatedReminder.toMap(),
            where: 'id = ?',
            whereArgs: [reminder.id],
          );

          // 更新内存中的记录
          final index = _reminders.indexWhere((r) => r.id == reminder.id);
          if (index != -1) {
            _reminders[index] = updatedReminder;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('刷新提醒失败: $e');
    }
  }

  // 从数据库加载提醒
  Future<void> _loadReminders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('reminders');
      _reminders = List.generate(
        maps.length,
        (i) => BillReminder.fromMap(maps[i]),
      );
    } catch (e) {
      throw Exception('加载账单提醒失败：$e');
    }
  }

  // 添加账单提醒
  Future<bool> addReminder(BillReminder reminder) async {
    _setLoading(true);
    try {
      // 如果设置了通知，则安排通知
      int? notificationId;
      if (_hasPermission && !reminder.completed) {
        notificationId = await _scheduleNotification(reminder);
      }

      // 使用可能的通知ID更新提醒
      final reminderWithNotification = reminder.copyWith(
        notificationId: notificationId,
      );

      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('reminders', reminderWithNotification.toMap());

      _reminders.add(reminderWithNotification.copyWith(id: id));
      _setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('添加账单提醒失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新账单提醒
  Future<bool> updateReminder(BillReminder reminder) async {
    _setLoading(true);
    try {
      if (reminder.id == null) {
        throw Exception('更新账单提醒需要有效的ID');
      }

      // 找到原提醒
      final oldIndex = _reminders.indexWhere((r) => r.id == reminder.id);
      if (oldIndex == -1) {
        throw Exception('找不到要更新的提醒');
      }
      final oldReminder = _reminders[oldIndex];

      // 如果有通知且提醒被修改或标记为完成，取消原通知
      if (oldReminder.notificationId != null) {
        await _notificationService.cancelNotification(
          oldReminder.notificationId!,
        );
      }

      // 如果需要且有权限，安排新通知
      int? notificationId;
      if (_hasPermission && !reminder.completed) {
        notificationId = await _scheduleNotification(reminder);
      }

      // 使用可能的通知ID更新提醒
      final reminderWithNotification = reminder.copyWith(
        notificationId: notificationId,
      );

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'reminders',
        reminderWithNotification.toMap(),
        where: 'id = ?',
        whereArgs: [reminder.id],
      );

      // 更新列表
      _reminders[oldIndex] = reminderWithNotification;
      _setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('更新账单提醒失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 标记提醒为完成
  Future<bool> markReminderAsCompleted(int id) async {
    _setLoading(true);
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw Exception('找不到指定的提醒');
      }

      final reminder = _reminders[index];

      // 如果有通知，取消通知
      if (reminder.notificationId != null) {
        await _notificationService.cancelNotification(reminder.notificationId!);
      }

      final updatedReminder = reminder.copyWith(
        completed: true,
        notificationId: null,
      );

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'reminders',
        updatedReminder.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _reminders[index] = updatedReminder;
      _setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('标记提醒为已完成失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除账单提醒
  Future<bool> deleteReminder(int id) async {
    _setLoading(true);
    try {
      // 找到提醒
      final reminder = _reminders.firstWhere(
        (r) => r.id == id,
        orElse: () => throw Exception('找不到指定的提醒'),
      );

      // 如果有通知，取消通知
      if (reminder.notificationId != null) {
        await _notificationService.cancelNotification(reminder.notificationId!);
      }

      final db = await DatabaseHelper.instance.database;
      await db.delete('reminders', where: 'id = ?', whereArgs: [id]);

      _reminders.removeWhere((r) => r.id == id);
      _setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除账单提醒失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 获取未完成的提醒
  List<BillReminder> getPendingReminders() {
    return _reminders.where((r) => !r.completed).toList();
  }

  // 获取已完成的提醒
  List<BillReminder> getCompletedReminders() {
    return _reminders.where((r) => r.completed).toList();
  }

  // 获取即将到期的提醒（7天内）
  List<BillReminder> getUpcomingReminders() {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));

    return _reminders
        .where(
          (r) =>
              !r.completed &&
              r.dueDate.isAfter(now) &&
              r.dueDate.isBefore(weekLater),
        )
        .toList();
  }

  // 获取已过期的提醒
  List<BillReminder> getOverdueReminders() {
    final now = DateTime.now();

    return _reminders
        .where((r) => !r.completed && r.dueDate.isBefore(now))
        .toList();
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // 安排通知
  Future<int> _scheduleNotification(BillReminder reminder) async {
    if (!_hasPermission) {
      print('无通知权限，跳过通知安排');
      return -1;
    }

    try {
      // 确定提醒时间（默认为到期日当天早上9点）
      final dueDate = reminder.dueDate;
      final reminderTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        9, // 早上9点
        0,
      );

      // 如果时间已过，则不安排通知
      final now = DateTime.now();
      if (reminderTime.isBefore(now)) {
        print('提醒时间已过，跳过通知安排');
        return -1;
      }

      // 安排通知
      final notificationId = await _notificationService.scheduleNotification(
        title: '账单到期提醒',
        body: '您的账单"${reminder.title}" (¥${reminder.amount.toStringAsFixed(2)}) 即将到期，请及时处理。',
        scheduledDate: reminderTime,
        payload: reminder.id?.toString(),
      );

      print('安排通知完成，通知ID：$notificationId');
      return notificationId;
    } catch (e) {
      print('安排通知错误: $e');
      return -1;
    }
  }

  // 获取循环类型的文本描述
  String _getRecurringTypeText(String? type) {
    switch (type) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return '定期';
    }
  }
}
