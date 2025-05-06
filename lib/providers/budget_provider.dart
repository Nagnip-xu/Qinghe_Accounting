import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import '../utils/date_util.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  Budget? _monthlyBudget;
  List<Budget> _categoryBudgets = [];
  bool _isLoading = false;
  String? _error;
  String _currentMonth = DateUtil.getMonthString(DateTime.now());
  Map<String, dynamic>? _budgetUsage;
  List<Budget> _budgets = [];
  final String _storageKey = 'budgets';

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
    loadBudgetData();
    notifyListeners();
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

  // 添加月度总预算
  Future<bool> addMonthlyBudget(Budget budget) async {
    _setLoading(true);

    try {
      // 确保是月度总预算
      budget = budget.copyWith(period: 'monthly');
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
