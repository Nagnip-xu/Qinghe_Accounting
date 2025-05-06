import 'package:sqflite/sqflite.dart';
import '../models/budget.dart';
import 'database_service.dart';
import 'transaction_service.dart';
import '../utils/date_util.dart';

class BudgetService {
  final DatabaseService _databaseService = DatabaseService();
  final TransactionService _transactionService = TransactionService();

  // 获取所有预算
  Future<List<Budget>> getAllBudgets() async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // 获取月度总预算
  Future<Budget?> getMonthlyBudget(String month) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ? AND isMonthly = ?',
      whereArgs: [month, 1],
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  // 获取分类预算
  Future<List<Budget>> getCategoryBudgets(String month) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ? AND isMonthly = ?',
      whereArgs: [month, 0],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // 获取单个预算
  Future<Budget?> getBudget(dynamic id) async {
    final Database db = await _databaseService.database;
    // 确保ID是整数类型
    final intId = id is String ? int.tryParse(id) ?? 0 : id;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [intId],
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  // 添加预算
  Future<int> addBudget(Budget budget) async {
    try {
      final Database db = await _databaseService.database;

      // 确保预算有关联的月份和数据类型正确
      Map<String, dynamic> budgetMap = budget.toMap();

      // 设置当前月份，如果未设置
      if (!budgetMap.containsKey('month') ||
          budgetMap['month'] == null ||
          budgetMap['month'].isEmpty) {
        budgetMap['month'] = DateUtil.getMonthString(DateTime.now());
      }

      // 检查是否为月度总预算
      bool isMonthly = budget.period == 'monthly';
      budgetMap['isMonthly'] = isMonthly ? 1 : 0;

      // 确保categoryId是整数
      if (budgetMap['categoryId'] != null) {
        if (budgetMap['categoryId'] is String) {
          budgetMap['categoryId'] = int.tryParse(budgetMap['categoryId']) ?? 0;
        }
      }

      print('添加预算: $budgetMap');
      return await db.insert('budgets', budgetMap);
    } catch (e) {
      print('添加预算失败: $e');
      rethrow;
    }
  }

  // 更新预算
  Future<int> updateBudget(Budget budget) async {
    try {
      final Database db = await _databaseService.database;

      // 获取预算的Map表示，确保字段类型正确
      final map = budget.toMap();

      // 确保id是整数类型
      final intId =
          budget.id is String ? int.tryParse(budget.id) ?? 0 : budget.id;

      // 确保categoryId是整数类型
      if (map['categoryId'] != null && map['categoryId'] is String) {
        map['categoryId'] = int.tryParse(map['categoryId']) ?? 0;
      }

      print('更新预算: $map');
      return await db.update(
        'budgets',
        map,
        where: 'id = ?',
        whereArgs: [intId],
      );
    } catch (e) {
      print('更新预算失败: $e');
      rethrow;
    }
  }

  // 删除预算
  Future<int> deleteBudget(dynamic id) async {
    try {
      final Database db = await _databaseService.database;
      // 确保ID是整数类型
      final intId = id is String ? int.tryParse(id) ?? 0 : id;
      return await db.delete('budgets', where: 'id = ?', whereArgs: [intId]);
    } catch (e) {
      print('删除预算失败: $e');
      rethrow;
    }
  }

  // 获取预算使用情况
  Future<Map<String, dynamic>> getBudgetUsage(String month) async {
    // 获取月度总预算
    final Budget? monthlyBudget = await getMonthlyBudget(month);
    final double totalBudget = monthlyBudget?.amount ?? 0.0;

    // 从month提取年和月参数(格式为yyyyMM)
    final int year = int.parse(month.substring(0, 4));
    final int monthNum = int.parse(month.substring(4, 6));

    // 获取月度总支出
    final double totalExpense = await _transactionService.getMonthlyExpense(
      year,
      monthNum,
    );

    // 计算总体预算使用百分比
    final double totalUsagePercentage =
        totalBudget > 0 ? (totalExpense / totalBudget) * 100 : 0;

    // 获取分类预算
    final List<Budget> categoryBudgets = await getCategoryBudgets(month);

    // 获取分类支出
    final Map<String, double> categoryExpenses = await _transactionService
        .getMonthlyExpenseByCategory(month);

    // 计算每个分类的预算使用情况
    final List<Map<String, dynamic>> categoryUsage = [];

    for (var budget in categoryBudgets) {
      final double expense = categoryExpenses[budget.categoryName] ?? 0.0;
      final double percentage =
          budget.amount > 0 ? (expense / budget.amount) * 100 : 0;

      categoryUsage.add({
        'id': budget.id,
        'categoryId': budget.categoryId,
        'categoryName': budget.categoryName,
        'categoryIcon': budget.categoryIcon,
        'categoryColor': budget.categoryColor,
        'budgetAmount': budget.amount,
        'expenseAmount': expense,
        'percentage': percentage,
        'remaining': budget.amount - expense,
      });
    }

    return {
      'totalBudget': totalBudget,
      'totalExpense': totalExpense,
      'totalPercentage': totalUsagePercentage,
      'totalRemaining': totalBudget - totalExpense,
      'categoryUsage': categoryUsage,
    };
  }
}
