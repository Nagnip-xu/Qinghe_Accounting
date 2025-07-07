import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

// 财务目标模型
class FinancialGoal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final bool completed;
  final String? icon;
  final String? color;

  FinancialGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.completed = false,
    this.icon,
    this.color,
  });

  // 将数据库记录转换为对象
  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      targetDate: DateTime.parse(map['targetDate']),
      completed: map['completed'] == 1,
      icon: map['icon'],
      color: map['color'],
    );
  }

  // 将对象转换为数据库记录
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'icon': icon,
      'color': color,
    };
  }

  // 创建已更新属性的副本
  FinancialGoal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool? completed,
    String? icon,
    String? color,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      completed: completed ?? this.completed,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  // 计算进度百分比
  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;

  // 距离目标日期剩余天数
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
}

// 财务目标Provider
class FinancialGoalProvider with ChangeNotifier {
  List<FinancialGoal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<FinancialGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 初始化财务目标
  Future<void> initGoals() async {
    _setLoading(true);
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('financial_goals');
      _goals = List.generate(
        maps.length,
        (i) => FinancialGoal.fromMap(maps[i]),
      );
      _setError(null);
    } catch (e) {
      _setError('获取财务目标失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取活跃的财务目标
  List<FinancialGoal> getActiveGoals() {
    return _goals.where((goal) => !goal.completed).toList();
  }

  // 获取已完成的财务目标
  List<FinancialGoal> getCompletedGoals() {
    return _goals.where((goal) => goal.completed).toList();
  }

  // 添加财务目标
  Future<bool> addGoal(FinancialGoal goal) async {
    _setLoading(true);
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('financial_goals', goal.toMap());
      _goals.add(goal.copyWith(id: id));
      _setError(null);
      return true;
    } catch (e) {
      _setError('添加财务目标失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新财务目标
  Future<bool> updateGoal(FinancialGoal goal) async {
    _setLoading(true);
    try {
      if (goal.id == null) {
        throw Exception('更新财务目标需要有效的ID');
      }

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'financial_goals',
        goal.toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );

      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
      }
      _setError(null);
      return true;
    } catch (e) {
      _setError('更新财务目标失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新目标进度
  Future<bool> updateGoalProgress(int id, double amountChange) async {
    _setLoading(true);
    try {
      // 查找目标
      final index = _goals.indexWhere((g) => g.id == id);
      if (index == -1) {
        throw Exception('找不到指定的财务目标');
      }

      final goal = _goals[index];
      final newAmount = goal.currentAmount + amountChange;

      // 确保新金额不小于0
      if (newAmount < 0) {
        throw Exception('目标进度不能小于0');
      }

      // 检查是否完成目标
      final completed = newAmount >= goal.targetAmount;

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        completed: completed,
      );

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'financial_goals',
        updatedGoal.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _goals[index] = updatedGoal;
      _setError(null);
      return true;
    } catch (e) {
      _setError('更新财务目标进度失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 标记目标为已完成
  Future<bool> markGoalAsCompleted(int id) async {
    _setLoading(true);
    try {
      final index = _goals.indexWhere((g) => g.id == id);
      if (index == -1) {
        throw Exception('找不到指定的财务目标');
      }

      final goal = _goals[index];
      final updatedGoal = goal.copyWith(completed: true);

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'financial_goals',
        updatedGoal.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      _goals[index] = updatedGoal;
      _setError(null);
      return true;
    } catch (e) {
      _setError('标记财务目标为已完成失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除财务目标
  Future<bool> deleteGoal(int id) async {
    _setLoading(true);
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('financial_goals', where: 'id = ?', whereArgs: [id]);

      _goals.removeWhere((g) => g.id == id);
      _setError(null);
      return true;
    } catch (e) {
      _setError('删除财务目标失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
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
}
