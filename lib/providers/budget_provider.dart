import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../services/notification_service.dart';
import '../utils/date_util.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  final NotificationService _notificationService = NotificationService();

  Budget? _monthlyBudget;
  List<Budget> _categoryBudgets = [];
  bool _isLoading = false;
  String? _error;
  String _currentMonth = DateUtil.getMonthString(DateTime.now());
  Map<String, dynamic>? _budgetUsage;
  List<Budget> _budgets = [];
  final String _storageKey = 'budgets';

  // 存储已经发送过通知的预算ID，避免重复通知
  final Set<String> _notifiedApproachingBudgets = {}; // 存储已通知即将超出的预算ID
  final Set<String> _notifiedExceededBudgets = {}; // 存储已通知超出的预算ID
  bool _totalBudgetApproachingNotified = false;
  bool _totalBudgetExceededNotified = false;

  Budget? get monthlyBudget => _monthlyBudget;
  List<Budget> get categoryBudgets => _categoryBudgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentMonth => _currentMonth;
  Map<String, dynamic>? get budgetUsage => _budgetUsage;
  List<Budget> get budgets => _budgets;

  BudgetProvider() {
    _loadBudgets();
  }

  // 设置当前月份
  void setCurrentMonth(String month) {
    _currentMonth = month;
    // 重置通知状态
    _resetNotificationStatus();
    loadBudgetData();
    notifyListeners();
  }

  // 重置通知状态
  void _resetNotificationStatus() {
    _notifiedApproachingBudgets.clear();
    _notifiedExceededBudgets.clear();
    _totalBudgetApproachingNotified = false;
    _totalBudgetExceededNotified = false;
  }

  // 初始化预算数据
  Future<void> initBudgets() async {
    _setLoading(true);

    try {
      await loadBudgetData();
      _setError(null);
    } catch (e) {
      _setError('获取预算数据失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 加载预算数据
  Future<void> loadBudgetData() async {
    _setLoading(true);

    try {
      await _fetchMonthlyBudget();
      await _fetchCategoryBudgets();
      await _fetchBudgetUsage();
      // 检查预算状态并发送通知
      _checkBudgetStatusAndNotify();
      _setError(null);
    } catch (e) {
      _setError('加载预算数据失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取月度总预算
  Future<void> _fetchMonthlyBudget() async {
    _monthlyBudget = await _budgetService.getMonthlyBudget(_currentMonth);
    notifyListeners();
  }

  // 获取分类预算
  Future<void> _fetchCategoryBudgets() async {
    _categoryBudgets = await _budgetService.getCategoryBudgets(_currentMonth);
    notifyListeners();
  }

  // 获取预算使用情况
  Future<void> _fetchBudgetUsage() async {
    _budgetUsage = await _budgetService.getBudgetUsage(_currentMonth);
    notifyListeners();
  }

  // 检查预算状态并发送通知
  Future<void> _checkBudgetStatusAndNotify() async {
    if (_budgetUsage == null) return;

    // 检查是否启用了通知
    bool isNotificationEnabled =
        await _notificationService.isNotificationEnabled();
    if (!isNotificationEnabled) return;

    // 检查是否有通知权限
    bool hasPermission = await _notificationService.hasPermission();
    if (!hasPermission) {
      // 尝试请求权限
      hasPermission = await _notificationService.requestPermission();
      if (!hasPermission) return; // 如果用户拒绝了权限，则不发送通知
    }

    // 检查月度总预算状态
    await _checkTotalBudgetStatus();

    // 检查分类预算状态
    await _checkCategoryBudgetStatus();
  }

  // 检查月度总预算状态
  Future<void> _checkTotalBudgetStatus() async {
    if (_budgetUsage == null) return;

    final double totalPercentage = _budgetUsage!['totalPercentage'] as double;

    // 如果总预算使用超过100%，而且还没有通知过
    if (totalPercentage >= 100 && !_totalBudgetExceededNotified) {
      await _notificationService.showTotalBudgetNotification(
        isExceeded: true,
        percentage: totalPercentage,
      );
      _totalBudgetExceededNotified = true;
      return; // 如果已经超出，就不需要发送即将超出的通知了
    }

    // 如果总预算使用超过80%但不超过100%，而且还没有通知过
    if (totalPercentage >= 80 &&
        totalPercentage < 100 &&
        !_totalBudgetApproachingNotified) {
      await _notificationService.showTotalBudgetNotification(
        isExceeded: false,
        percentage: totalPercentage,
      );
      _totalBudgetApproachingNotified = true;
    }
  }

  // 检查分类预算状态
  Future<void> _checkCategoryBudgetStatus() async {
    if (_budgetUsage == null) return;

    final categoryUsages =
        _budgetUsage!['categoryUsage'] as List<Map<String, dynamic>>;

    for (var categoryUsage in categoryUsages) {
      final String categoryId = categoryUsage['id'].toString();
      final String categoryName = categoryUsage['categoryName'] as String;
      final double percentage = categoryUsage['percentage'] as double;

      // 如果分类预算使用超过100%，而且还没有通知过
      if (percentage >= 100 && !_notifiedExceededBudgets.contains(categoryId)) {
        await _notificationService.showBudgetExceededNotification(
          categoryName: categoryName,
          percentage: percentage,
        );
        _notifiedExceededBudgets.add(categoryId);
        continue; // 如果已经超出，就不需要发送即将超出的通知了
      }

      // 如果分类预算使用超过80%但不超过100%，而且还没有通知过
      if (percentage >= 80 &&
          percentage < 100 &&
          !_notifiedApproachingBudgets.contains(categoryId)) {
        await _notificationService.showBudgetApproachingLimitNotification(
          categoryName: categoryName,
          percentage: percentage,
        );
        _notifiedApproachingBudgets.add(categoryId);
      }
    }
  }

  // 添加月度总预算
  Future<bool> addMonthlyBudget(Budget budget) async {
    _setLoading(true);

    try {
      // 确保是月度总预算并设置正确的月份
      budget = budget.copyWith(
        period: 'monthly',
        month: budget.month ?? _currentMonth, // 使用传入的月份或当前选择的月份
      );
      await _budgetService.addBudget(budget);
      await loadBudgetData();
      _setError(null);
      return true;
    } catch (e) {
      _setError('添加月度总预算失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 添加分类预算
  Future<bool> addCategoryBudget(Budget budget) async {
    _setLoading(true);

    try {
      // 确保设置正确的月份
      budget = budget.copyWith(
        month: budget.month ?? _currentMonth, // 使用传入的月份或当前选择的月份
      );
      await _budgetService.addBudget(budget);
      await loadBudgetData();
      _setError(null);
      return true;
    } catch (e) {
      _setError('添加分类预算失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新预算
  Future<bool> updateBudget(Budget budget) async {
    _setLoading(true);

    try {
      await _budgetService.updateBudget(budget);
      await loadBudgetData();
      _setError(null);
      return true;
    } catch (e) {
      _setError('更新预算失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除预算
  Future<bool> deleteBudget(int id) async {
    _setLoading(true);

    try {
      await _budgetService.deleteBudget(id);
      await loadBudgetData();
      _setError(null);
      return true;
    } catch (e) {
      _setError('删除预算失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsString = prefs.getString(_storageKey);

    if (budgetsString != null) {
      final budgetsJson = jsonDecode(budgetsString) as List;
      _budgets = budgetsJson.map((item) => Budget.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = _budgets.map((budget) => budget.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(budgetsJson));
  }

  double getTotalBudget() {
    return _budgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  Budget? getBudgetByCategory(String categoryId) {
    try {
      return _budgets.firstWhere((budget) => budget.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  double getSpentPercentage(String categoryId, double spent) {
    final budget = getBudgetByCategory(categoryId);
    if (budget == null || budget.amount == 0) return 0;
    return (spent / budget.amount).clamp(0.0, 1.0);
  }

  bool isCategoryBudgeted(String categoryId) {
    return _budgets.any((budget) => budget.categoryId == categoryId);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
