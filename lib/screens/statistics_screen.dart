import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/month_year_picker.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/transaction_service.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<FlSpot> _dailyExpenses = [];
  List<Map<String, dynamic>> _categories = [];
  final TransactionService _transactionService = TransactionService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadStatisticsData();
  }

  // 根据选择的年月加载统计数据
  Future<void> _loadStatisticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 格式化年月字符串，如: 2025-04-01 00:00:00
      final String yearMonth = DateFormat('yyyy-MM').format(_selectedDate);

      // 获取月度收入和支出
      await _fetchMonthlySummary(yearMonth);

      // 获取每日支出趋势
      await _fetchDailyExpenses(yearMonth);

      // 获取支出分类数据
      await _fetchCategoryBreakdown(yearMonth);
    } catch (e) {
      debugPrint('加载统计数据错误: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 获取月度收入和支出总额
  Future<void> _fetchMonthlySummary(String yearMonth) async {
    final Database db = await _databaseService.database;

    // 查询月度收入
    final incomeResult = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = '收入' AND date LIKE '$yearMonth-%'
    ''');
    _totalIncome =
        incomeResult.first['total'] != null
            ? double.parse(incomeResult.first['total'].toString())
            : 0.0;

    // 查询月度支出
    final expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = '支出' AND date LIKE '$yearMonth-%'
    ''');
    _totalExpense =
        expenseResult.first['total'] != null
            ? double.parse(expenseResult.first['total'].toString())
            : 0.0;
  }

  // 获取每日支出趋势数据
  Future<void> _fetchDailyExpenses(String yearMonth) async {
    final Database db = await _databaseService.database;

    // 获取该月天数和判断是否是大月
    final lastDay = DateUtil.getLastDayOfMonth(_selectedDate);
    final bool isCurrentMonthBig = DateUtil.isBigMonth(_selectedDate.month);

    // 清空原有数据
    _dailyExpenses = [];

    // 创建分组列表
    List<Map<String, dynamic>> groupedDays = [];

    // 对于大月的31天，最后三天（29,30,31）作为一组
    if (isCurrentMonthBig && lastDay == 31) {
      // 1-28日按照2天一组
      for (int i = 1; i <= 28; i += 2) {
        int endDay = i + 1;
        groupedDays.add({
          'startDay': i,
          'endDay': endDay,
          'label': '$i-$endDay日',
          'amount': 0.0,
        });
      }

      // 29-31日为最后一组
      groupedDays.add({
        'startDay': 29,
        'endDay': 31,
        'label': '29-31日',
        'amount': 0.0,
      });
    } else {
      // 非31天的月份，正常每2天一组
      for (int i = 1; i <= lastDay; i += 2) {
        int endDay = i + 1 > lastDay ? lastDay : i + 1;
        groupedDays.add({
          'startDay': i,
          'endDay': endDay,
          'label': '$i-$endDay日',
          'amount': 0.0,
        });
      }
    }

    // 查询每日支出数据
    final dailyExpenseResult = await db.rawQuery('''
      SELECT 
        strftime('%d', date) as day, 
        SUM(amount) as total
      FROM transactions
      WHERE type = '支出' AND date LIKE '$yearMonth-%'
      GROUP BY strftime('%d', date)
    ''');

    // 将每日数据映射到对应的组
    for (var row in dailyExpenseResult) {
      if (row['day'] != null && row['total'] != null) {
        final day = int.parse(row['day'].toString());
        final amount = double.parse(row['total'].toString());

        // 找到该天所属的组
        for (var group in groupedDays) {
          if (day >= group['startDay'] && day <= group['endDay']) {
            group['amount'] = (group['amount'] as double) + amount;
            break;
          }
        }
      }
    }

    // 将分组数据转换为FlSpot列表用于图表
    _dailyExpenses =
        groupedDays.map((group) {
          // 使用组的中间日期作为X轴坐标
          double xPosition =
              ((group['startDay'] as int) + (group['endDay'] as int)) / 2;
          return FlSpot(xPosition, group['amount'] as double);
        }).toList();
  }

  // 获取支出分类明细
  Future<void> _fetchCategoryBreakdown(String yearMonth) async {
    final Database db = await _databaseService.database;

    // 获取总支出金额
    double totalExpense = _totalExpense;

    // 定义默认分类列表
    final List<String> defaultCategories = ['餐饮', '交通', '购物', '娱乐', '账单', '其他'];

    // 默认图标和颜色映射
    final Map<String, Map<String, dynamic>> defaultCategoryInfo = {
      '餐饮': {'icon': 'restaurant', 'color': AppColors.foodColor},
      '交通': {'icon': 'directions_car', 'color': AppColors.transportColor},
      '购物': {'icon': 'shopping_bag', 'color': AppColors.shoppingColor},
      '娱乐': {'icon': 'movie', 'color': AppColors.entertainmentColor},
      '账单': {'icon': 'receipt_long', 'color': AppColors.billsColor},
      '其他': {'icon': 'more_horiz', 'color': AppColors.otherColor},
    };

    // 如果没有支出，创建默认分类列表但金额为0
    if (totalExpense <= 0) {
      _categories =
          defaultCategories.map((categoryName) {
            final info = defaultCategoryInfo[categoryName]!;
            return {
              'name': categoryName,
              'amount': 0.0,
              'percentage': 0.0,
              'color': info['color'] as Color,
              'icon': getIconByName(info['icon'] as String),
            };
          }).toList();
      return;
    }

    // 查询分类支出汇总
    final categoriesResult = await db.rawQuery('''
      SELECT 
        categoryName, 
        categoryIcon, 
        categoryColor, 
        SUM(amount) as total
      FROM transactions
      WHERE type = '支出' AND date LIKE '$yearMonth-%'
      GROUP BY categoryName
      ORDER BY total DESC
    ''');

    // 处理数据库结果
    List<Map<String, dynamic>> allCategories = [];
    Set<String> processedCategories = {}; // 跟踪已处理的分类名称

    // 将数据库结果转换为分类列表
    for (var row in categoriesResult) {
      final categoryName = row['categoryName'] as String;
      processedCategories.add(categoryName);

      final categoryIcon = row['categoryIcon'] as String;
      String? categoryColor = row['categoryColor'] as String?;
      final total = double.parse(row['total'].toString());
      final percentage = (total / totalExpense * 100).toStringAsFixed(1);

      // 解析颜色
      Color color;
      try {
        if (categoryColor != null && categoryColor.isNotEmpty) {
          if (categoryColor.startsWith('0x')) {
            color = Color(int.parse(categoryColor));
          } else {
            color = Color(
              int.parse('0xFF${categoryColor.replaceAll('#', '')}'),
            );
          }
        } else if (defaultCategoryInfo.containsKey(categoryName)) {
          // 使用默认颜色
          color = defaultCategoryInfo[categoryName]!['color'] as Color;
        } else {
          color = AppColors.otherColor;
        }
      } catch (e) {
        // 默认颜色
        if (defaultCategoryInfo.containsKey(categoryName)) {
          color = defaultCategoryInfo[categoryName]!['color'] as Color;
        } else {
          color = AppColors.otherColor;
        }
      }

      // 解析图标
      IconData icon;
      try {
        icon = getIconByName(categoryIcon);
      } catch (e) {
        if (defaultCategoryInfo.containsKey(categoryName)) {
          icon = getIconByName(
            defaultCategoryInfo[categoryName]!['icon'] as String,
          );
        } else {
          icon = Icons.category;
        }
      }

      allCategories.add({
        'name': categoryName,
        'amount': total,
        'percentage': double.parse(percentage),
        'color': color,
        'icon': icon,
      });
    }

    // 添加默认分类中不在数据库结果中的分类（设置为0金额）
    for (String categoryName in defaultCategories) {
      if (!processedCategories.contains(categoryName)) {
        final info = defaultCategoryInfo[categoryName]!;
        allCategories.add({
          'name': categoryName,
          'amount': 0.0,
          'percentage': 0.0,
          'color': info['color'] as Color,
          'icon': getIconByName(info['icon'] as String),
        });
      }
    }

    // 按支出金额从高到低排序
    allCategories.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

    _categories = allCategories;
  }

  // 根据字符串获取对应的图标
  IconData getIconByName(String iconName) {
    switch (iconName) {
      case 'restaurant':
      case 'utensils':
      case 'food':
        return Icons.restaurant;
      case 'car':
      case 'directions_car':
      case 'bus':
      case 'subway':
      case 'train':
        return Icons.directions_car;
      case 'cart-shopping':
      case 'shopping_bag':
      case 'shopping_cart':
      case 'shopping':
        return Icons.shopping_bag;
      case 'film':
      case 'movie':
      case 'entertainment':
      case 'videogame':
        return Icons.movie;
      case 'receipt':
      case 'receipt_long':
      case 'bill':
      case 'invoice':
        return Icons.receipt_long;
      case 'medical':
      case 'health':
      case 'healing':
      case 'local_hospital':
        return Icons.local_hospital;
      case 'education':
      case 'school':
      case 'book':
      case 'class':
        return Icons.school;
      case 'more':
      case 'more_horiz':
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header - 优化标题UI
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: themeColor.withOpacity(0.1),
                                width: 2.0,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '统计',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : themeColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.bar_chart,
                                color: isDarkMode ? Colors.white : themeColor,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Month picker
                        Center(
                          child: MonthYearPicker(
                            selectedDate: _selectedDate,
                            onDateChanged: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadStatisticsData();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Income and expense summary
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: '收入',
                                amount: '¥${_formatCurrency(_totalIncome)}',
                                iconData: Icons.arrow_upward,
                                iconColor: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                title: '支出',
                                amount: '¥${_formatCurrency(_totalExpense)}',
                                iconData: Icons.arrow_downward,
                                iconColor: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 支出趋势图
                        Row(
                          children: [
                            Icon(
                              Icons.show_chart,
                              color:
                                  isDarkMode
                                      ? Colors.white70
                                      : AppColors.expense,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '支出趋势',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExpenseTrendCard(),
                        const SizedBox(height: 24),

                        // Category Breakdown
                        Row(
                          children: [
                            Icon(
                              Icons.pie_chart,
                              color:
                                  isDarkMode
                                      ? Colors.white70
                                      : AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '支出分类',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category breakdown list
                        _buildCategoryList(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  // 格式化货币显示
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    return formatter.format(amount);
  }

  // 构建收入支出卡片
  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData iconData,
    required Color iconColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side:
            title == '收入'
                ? BorderSide(color: AppColors.income.withOpacity(0.3), width: 1)
                : BorderSide(
                  color: AppColors.expense.withOpacity(0.3),
                  width: 1,
                ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建支出趋势卡片
  Widget _buildExpenseTrendCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '每日支出曲线',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color:
                  isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: _calculateInterval(),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailyExpenses,
                    isCurved: true,
                    color: AppColors.expense, // 恢复使用支出颜色
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.expense.withOpacity(0.2), // 恢复使用支出颜色
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor:
                        isDarkMode ? Colors.grey[800]! : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)}¥',
                          TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 检查是否有分类数据
    if (_categories.isEmpty) {
      // 这种情况理论上不应该发生，因为我们已经确保至少有默认分类
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '暂无支出分类数据',
          style: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    // 显示分类列表，包括所有有数据的分类和默认分类
    return ListView.builder(
      itemCount: _categories.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final Color categoryColor = category['color'] as Color;
        final double amount = category['amount'] as double;
        final double percentage = category['percentage'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${_formatCurrency(amount)}',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? Colors.white70
                                : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: percentage * 100 / 100,
                          height: 6,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 计算图表Y轴间隔
  double _calculateInterval() {
    // 找出最大支出金额，用于设置图表Y轴的最大值
    final maxExpense =
        _dailyExpenses.isEmpty
            ? 100.0
            : _dailyExpenses
                .map((spot) => spot.y)
                .reduce((max, y) => max > y ? max : y);

    // 根据最大值确定合适的间隔
    if (maxExpense <= 500) {
      return 100; // 小于500，间隔为100
    } else if (maxExpense <= 2000) {
      return 500; // 小于2000，间隔为500
    } else if (maxExpense <= 5000) {
      return 1000; // 小于5000，间隔为1000
    } else if (maxExpense <= 10000) {
      return 2000; // 小于10000，间隔为2000
    } else {
      return 5000; // 大于10000，间隔为5000
    }
  }
}

// 日期工具类
class DateUtil {
  // 获取月份的最后一天
  static int getLastDayOfMonth(DateTime date) {
    final nextMonth =
        (date.month < 12)
            ? DateTime(date.year, date.month + 1, 1)
            : DateTime(date.year + 1, 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1)).day;
    return lastDay;
  }

  // 判断是否是大月（31天）
  static bool isBigMonth(int month) {
    return [1, 3, 5, 7, 8, 10, 12].contains(month);
  }
}
