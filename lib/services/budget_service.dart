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

    // 规范化月份格式
    final normalizedMonth = _normalizeMonthFormat(month);
    print("[预算] 获取月度总预算: 原始月份=$month, 规范化后=$normalizedMonth");

    // 先尝试标准格式
    List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ? AND isMonthly = ?',
      whereArgs: [normalizedMonth, 1],
    );

    // 如果找不到记录，尝试旧格式
    if (maps.isEmpty && month != normalizedMonth) {
      maps = await db.query(
        'budgets',
        where: 'month = ? AND isMonthly = ?',
        whereArgs: [month, 1],
      );
    }

    if (maps.isNotEmpty) {
      print("[预算] 找到月度总预算: ${maps.first}");
      return Budget.fromMap(maps.first);
    }

    print("[预算] 未找到月度总预算");
    return null;
  }

  // 获取分类预算
  Future<List<Budget>> getCategoryBudgets(String month) async {
    final Database db = await _databaseService.database;

    // 规范化月份格式
    final normalizedMonth = _normalizeMonthFormat(month);
    print("[预算] 获取分类预算: 原始月份=$month, 规范化后=$normalizedMonth");

    // 先尝试标准格式
    String sql = "SELECT * FROM budgets WHERE month = ? AND isMonthly = ?";
    List<dynamic> args = [normalizedMonth, 0];
    print("[预算] 执行SQL: $sql, 参数: $args");

    List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ? AND isMonthly = ?',
      whereArgs: [normalizedMonth, 0],
    );

    // 如果找不到记录，尝试旧格式
    if (maps.isEmpty && month != normalizedMonth) {
      print("[预算] 使用旧格式查询: month=$month, isMonthly=0");
      maps = await db.query(
        'budgets',
        where: 'month = ? AND isMonthly = ?',
        whereArgs: [month, 0],
      );
    }

    // 查询所有记录以验证数据存在
    if (maps.isEmpty) {
      final allBudgets = await db.query('budgets');
      print("[预算] 数据库中所有预算: ${allBudgets.length}条");
      for (var budget in allBudgets) {
        print(
          "[预算] - ID=${budget['id']}, 名称=${budget['categoryName']}, 月份=${budget['month']}, isMonthly=${budget['isMonthly']}",
        );
      }
    }

    final result = List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
    print("[预算] 找到${result.length}个分类预算");
    return result;
  }

  // 规范化月份格式为 yyyy-MM
  String _normalizeMonthFormat(String month) {
    // 如果已经是 yyyy-MM 格式
    if (month.contains('-')) {
      return month;
    }

    // 如果是 yyyyMM 格式
    if (month.length == 6) {
      final year = month.substring(0, 4);
      final monthDigit = month.substring(4, 6);
      return '$year-$monthDigit';
    }

    return month; // 返回原值，让调用方处理错误
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
      bool isMonthly =
          budget.period == 'monthly' &&
          (budget.categoryId == 0 ||
              budget.categoryId == '0' ||
              budget.categoryId == '');
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

      // 确保isMonthly字段正确设置
      bool isMonthly =
          budget.period == 'monthly' &&
          (budget.categoryId == 0 ||
              budget.categoryId == '0' ||
              budget.categoryId == '');
      map['isMonthly'] = isMonthly ? 1 : 0;

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
    print("[预算] 获取预算使用情况: month=$month");

    // 规范化月份格式
    final normalizedMonth = _normalizeMonthFormat(month);
    print("[预算] 规范化后的月份: $normalizedMonth");

    // 获取月度总预算
    final Budget? monthlyBudget = await getMonthlyBudget(normalizedMonth);
    final double totalBudget = monthlyBudget?.amount ?? 0.0;

    print("[预算] 月度总预算: ${monthlyBudget?.toMap()}");

    // 从month提取年和月参数(格式为yyyy-MM)
    final String yearMonth =
        normalizedMonth.contains('-') ? normalizedMonth : month;
    final parts =
        yearMonth.contains('-')
            ? yearMonth.split('-')
            : [yearMonth.substring(0, 4), yearMonth.substring(4, 6)];

    final int year = int.parse(parts[0]);
    final int monthNum = int.parse(parts[1]);

    print("[预算] 解析月份: year=$year, month=$monthNum");

    // 获取月度总支出
    final double totalExpense = await _transactionService.getMonthlyExpense(
      year,
      monthNum,
    );

    print("[预算] 月度总支出: $totalExpense");

    // 计算总体预算使用百分比
    final double totalUsagePercentage =
        totalBudget > 0 ? (totalExpense / totalBudget) * 100 : 0;

    // 获取分类预算
    final List<Budget> categoryBudgets = await getCategoryBudgets(
      normalizedMonth,
    );

    print("[预算] 分类预算列表: ${categoryBudgets.length}个");
    for (var budget in categoryBudgets) {
      print(
        "[预算] - ${budget.categoryName}: ${budget.amount}元, ID=${budget.id}",
      );
    }

    // 获取分类支出
    final Map<String, double> categoryExpenses = await _transactionService
        .getMonthlyExpenseByCategory(yearMonth.replaceAll('-', ''));

    print("[预算] 分类支出: $categoryExpenses");

    // 计算每个分类的预算使用情况
    final List<Map<String, dynamic>> categoryUsage = [];

    // 创建一个辅助函数，判断一个小类支出是否属于某个大类预算
    bool isExpenseBelongToBudget(String expenseCategory, Budget budget) {
      final String budgetCategory = budget.categoryName.toLowerCase();
      final String expenseCat = expenseCategory.toLowerCase();

      // 完全匹配
      if (expenseCat == budgetCategory) {
        return true;
      }

      // 大类包含小类（如"餐饮"预算包含"午餐"支出）
      if (expenseCat.contains(budgetCategory) ||
          budgetCategory.contains(expenseCat)) {
        return true;
      }

      // 针对特定分类的匹配规则
      switch (budgetCategory) {
        case "餐饮":
          return expenseCat.contains("饭") ||
              expenseCat.contains("餐") ||
              expenseCat.contains("吃") ||
              expenseCat.contains("食");
        case "交通":
          return expenseCat.contains("车") ||
              expenseCat.contains("船") ||
              expenseCat.contains("机") ||
              expenseCat.contains("路费");
        case "购物":
          return expenseCat.contains("买") ||
              expenseCat.contains("购") ||
              expenseCat.contains("商品");
        case "娱乐":
          return expenseCat.contains("玩") ||
              expenseCat.contains("游") ||
              expenseCat.contains("乐");
        case "医疗":
          return expenseCat.contains("药") ||
              expenseCat.contains("医") ||
              expenseCat.contains("诊") ||
              expenseCat.contains("院");
        default:
          return false;
      }
    }

    for (var budget in categoryBudgets) {
      double totalExpense = 0.0;
      List<String> matchedCategories = [];

      // 遍历所有支出分类，匹配属于该预算的支出
      for (var entry in categoryExpenses.entries) {
        if (isExpenseBelongToBudget(entry.key, budget)) {
          totalExpense += entry.value;
          matchedCategories.add("${entry.key}(¥${entry.value})");
        }
      }

      // 如果有匹配到的支出分类，打印日志
      if (matchedCategories.isNotEmpty) {
        print(
          '分类预算匹配: "${budget.categoryName}"预算匹配到支出: ${matchedCategories.join(", ")}, 总金额=$totalExpense',
        );
      } else {
        print('分类预算"${budget.categoryName}"没有匹配到任何支出');
      }

      final double percentage =
          budget.amount > 0 ? (totalExpense / budget.amount) * 100 : 0;

      categoryUsage.add({
        'id': budget.id,
        'categoryId': budget.categoryId,
        'categoryName': budget.categoryName,
        'categoryIcon': budget.categoryIcon,
        'categoryColor': budget.categoryColor,
        'budgetAmount': budget.amount,
        'expenseAmount': totalExpense,
        'percentage': percentage,
        'remaining': budget.amount - totalExpense,
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
