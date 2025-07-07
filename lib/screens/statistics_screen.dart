import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/colors.dart';
import '../constants/category_icons.dart';
import '../providers/theme_provider.dart';
import '../widgets/month_year_picker.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/transaction_service.dart';
import '../services/database_service.dart';
import 'category_detail_screen.dart';

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

    // 获取该月天数
    final lastDay = DateUtil.getLastDayOfMonth(_selectedDate);

    // 清空原有数据
    _dailyExpenses = [];

    // 按照每天记录准备数据点，后续在图表上展示时才显示5天间隔的标签
    List<FlSpot> dailySpots = List.generate(lastDay, (index) {
      // 创建初始每天的数据点，金额为0
      return FlSpot((index + 1).toDouble(), 0);
    });

    // 查询每日支出数据
    final dailyExpenseResult = await db.rawQuery('''
      SELECT 
        strftime('%d', date) as day, 
        SUM(amount) as total
      FROM transactions
      WHERE type = '支出' AND date LIKE '$yearMonth-%'
      GROUP BY strftime('%d', date)
    ''');

    // 将查询结果映射到对应的日期
    for (var row in dailyExpenseResult) {
      if (row['day'] != null && row['total'] != null) {
        final day = int.parse(row['day'].toString());
        if (day > 0 && day <= lastDay) {
          final amount = double.parse(row['total'].toString());
          // 数组索引从0开始，日期从1开始，所以要减1
          dailySpots[day - 1] = FlSpot(day.toDouble(), amount);
        }
      }
    }

    // 更新状态
    setState(() {
      _dailyExpenses = dailySpots;
    });
  }

  // 获取支出分类明细
  Future<void> _fetchCategoryBreakdown(String yearMonth) async {
    final Database db = await _databaseService.database;

    // 获取总支出金额
    double totalExpense = _totalExpense;

    // 定义默认分类列表和颜色
    final List<String> defaultCategories = [
      '餐饮',
      '交通',
      '购物',
      '娱乐',
      '住房',
      '医疗',
      '教育',
      '其他',
    ];

    // 从数据库查询所有分类，未指定颜色时使用CategoryColors获取颜色
    if (totalExpense <= 0) {
      _categories =
          defaultCategories.map((categoryName) {
            return {
              'name': categoryName,
              'amount': 0.0,
              'percentage': 0.0,
              'color': CategoryColors.getColor(categoryName),
              'icon': getIconByName(categoryName),
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

      // 解析颜色 - 始终使用CategoryColors获取颜色，确保与添加交易页面一致
      Color color = CategoryColors.getColor(categoryName);

      allCategories.add({
        'name': categoryName,
        'amount': total,
        'percentage': double.parse(percentage),
        'color': color,
        'icon': getIconByName(categoryIcon),
      });
    }

    // 添加默认分类中不在数据库结果中的分类（设置为0金额）
    for (String categoryName in defaultCategories) {
      if (!processedCategories.contains(categoryName)) {
        allCategories.add({
          'name': categoryName,
          'amount': 0.0,
          'percentage': 0.0,
          'color': CategoryColors.getColor(categoryName),
          'icon': getIconByName(categoryName),
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
      // 餐饮类
      case 'restaurant':
      case 'utensils':
      case 'food':
      case '餐饮':
        return FontAwesomeIcons.utensils;
      case 'bread-slice':
      case '早餐':
        return FontAwesomeIcons.breadSlice;
      case 'bowl-food':
      case '午餐':
        return FontAwesomeIcons.bowlFood;
      case 'bowl-rice':
      case '晚餐':
        return FontAwesomeIcons.bowlRice;
      case 'candy-cane':
      case '零食':
        return FontAwesomeIcons.candyCane;

      // 交通类
      case 'car':
      case 'directions_car':
      case '交通':
        return FontAwesomeIcons.car;
      case 'taxi':
      case '打车':
        return FontAwesomeIcons.taxi;
      case 'bus':
      case '公交':
        return FontAwesomeIcons.bus;
      case 'train-subway':
      case 'subway':
      case '地铁':
        return FontAwesomeIcons.trainSubway;

      // 购物类
      case 'bag-shopping':
      case 'shopping_bag':
      case 'shopping_cart':
      case 'shopping':
      case '购物':
        return FontAwesomeIcons.bagShopping;
      case 'shirt':
      case '服装':
        return FontAwesomeIcons.shirt;
      case 'spray-can':
      case '化妆':
        return FontAwesomeIcons.sprayCan;
      case 'laptop':
      case '数码':
        return FontAwesomeIcons.laptop;
      case 'couch':
      case '家居':
        return FontAwesomeIcons.couch;

      // 娱乐类
      case 'gamepad':
      case 'movie':
      case 'entertainment':
      case 'videogame':
      case '娱乐':
        return FontAwesomeIcons.gamepad;
      case 'film':
      case '电影':
        return FontAwesomeIcons.film;
      case 'chess':
      case '游戏':
        return FontAwesomeIcons.chess;
      case 'plane':
      case '旅游':
        return FontAwesomeIcons.plane;

      // 住房类
      case 'house':
      case '住房':
        return FontAwesomeIcons.house;
      case 'house-chimney':
      case '房租':
        return FontAwesomeIcons.houseChimney;
      case 'droplet':
      case '水费':
        return FontAwesomeIcons.droplet;
      case 'bolt':
      case '电费':
        return FontAwesomeIcons.bolt;
      case 'fire':
      case '燃气费':
        return FontAwesomeIcons.fire;
      case 'wifi':
      case '网费':
        return FontAwesomeIcons.wifi;
      case 'phone':
      case '话费':
        return FontAwesomeIcons.phone;

      // 医疗类
      case 'medical':
      case 'health':
      case 'healing':
      case 'local_hospital':
      case 'suitcase-medical':
      case '医疗':
        return FontAwesomeIcons.suitcaseMedical;
      case 'pills':
      case '药品':
        return FontAwesomeIcons.pills;
      case 'hospital-user':
      case '挂号':
        return FontAwesomeIcons.hospitalUser;

      // 教育类
      case 'education':
      case 'school':
      case 'class':
      case 'graduation-cap':
      case '教育':
        return FontAwesomeIcons.graduationCap;
      case 'book':
      case '学费':
        return FontAwesomeIcons.book;
      case 'book-open':
      case '书籍':
        return FontAwesomeIcons.bookOpen;

      // 收入类
      case 'money-bill-1':
      case '工资':
        return FontAwesomeIcons.moneyBill1;
      case 'award':
      case '奖金':
        return FontAwesomeIcons.award;
      case 'briefcase':
      case '兼职':
        return FontAwesomeIcons.briefcase;
      case 'chart-line':
      case '投资':
        return FontAwesomeIcons.chartLine;

      // 其他支出
      case 'baby':
      case '孩子':
        return FontAwesomeIcons.baby;
      case 'paw':
      case '宠物':
        return FontAwesomeIcons.paw;
      case 'money-bill-trend-up':
      case '理财':
        return FontAwesomeIcons.moneyBillTrendUp;
      case 'user-group':
      case '社交':
        return FontAwesomeIcons.userGroup;
      case 'gift':
      case '礼物':
        return FontAwesomeIcons.gift;

      // 账单类
      case 'receipt':
      case 'receipt_long':
      case 'bill':
      case 'invoice':
        return FontAwesomeIcons.receipt;

      // 其他
      case 'more':
      case 'more_horiz':
      case 'other':
      case 'ellipsis':
      case '其他':
        return FontAwesomeIcons.ellipsis;
      case 'tag':
      case 'custom':
        return FontAwesomeIcons.tag;
      default:
        return FontAwesomeIcons.receipt;
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
    final expenseColor = AppColors.expense;

    // 计算Y轴最大值
    final yInterval = _calculateInterval();
    final maxExpense =
        _dailyExpenses.isEmpty
            ? 0.0
            : (_dailyExpenses
                .map((spot) => spot.y)
                .reduce((max, y) => max > y ? max : y));

    // 确保Y轴最大值至少为300元，或者比最大支出多一个间隔
    final maxY =
        maxExpense > 300
            ? ((maxExpense / yInterval).ceil() + 1) * yInterval
            : 300.0;

    // 获取当月天数
    final lastDay = DateUtil.getLastDayOfMonth(_selectedDate);

    // 固定的X轴标签位置
    final List<int> fixedXLabels = [1, 5, 10, 15, 20, 25, lastDay];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          // 标题和最大值显示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // 显示最大值
              if (_dailyExpenses.isNotEmpty && maxExpense > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: expenseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '最高: ¥${maxExpense.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: expenseColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor:
                              isDarkMode ? Colors.grey[800]! : Colors.white,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tooltipMargin: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.x.toInt()}日: ¥${spot.y.toStringAsFixed(0)}',
                                TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        touchSpotThreshold: 20,
                        handleBuiltInTouches: true,
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50, // 固定为50元间隔
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!.withOpacity(0.3)
                                    : Colors.grey[300]!,
                            strokeWidth: 1,
                            dashArray: [5, 5], // 虚线效果
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              // 确保显示0, 50, 100, 150, 200, 250, 300
                              // 超过300后，根据计算的间隔显示
                              if (maxY <= 300) {
                                // 300以内固定显示这些刻度
                                if (value % 50 != 0 && value != 0) {
                                  return const SizedBox.shrink();
                                }
                              } else {
                                // 300以上使用计算的间隔
                                if (value % yInterval != 0 && value != 0) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                            interval:
                                maxY <= 300
                                    ? 50
                                    : yInterval, // 300以内用50间隔，超过300使用动态间隔
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
                              // 只在固定位置显示标签: 1,5,10,15,20,25,最后一天
                              final day = value.toInt();
                              if (!fixedXLabels.contains(day)) {
                                return const SizedBox.shrink();
                              }

                              // 所有日期标签使用相同样式
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  day.toString(),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!.withOpacity(0.5)
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!.withOpacity(0.5)
                                    : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      minX: 1,
                      maxX: lastDay.toDouble(),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dailyExpenses,
                          isCurved: true,
                          curveSmoothness: 0.2, // 降低曲线平滑度，减少过冲
                          preventCurveOverShooting: true, // 防止曲线过冲
                          color: expenseColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: expenseColor,
                                strokeWidth: 1,
                                strokeColor:
                                    isDarkMode ? Colors.black : Colors.white,
                              );
                            },
                            checkToShowDot: (spot, barData) {
                              // 只在有值且值大于0的地方显示点
                              return spot.y > 0;
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                expenseColor.withOpacity(0.3),
                                expenseColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            // 确保区域不会低于0
                            cutOffY: 0,
                            applyCutOffY: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 在0的下方添加"元/天"标识，放在坐标轴左下角
              Positioned(
                left: 2,
                bottom: 2, // 调整到更靠近左下角
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[800]!.withOpacity(0.7)
                            : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '元/天',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final yearMonth = DateFormat('yyyy-MM').format(_selectedDate);

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
        final String categoryName = category['name'] as String;
        final IconData categoryIcon = category['icon'] as IconData;

        return GestureDetector(
          onTap: () {
            // 导航到分类详情页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CategoryDetailScreen(
                      categoryName: categoryName,
                      categoryColor: categoryColor,
                      categoryIcon: categoryIcon,
                      initialMonth: yearMonth,
                    ),
              ),
            );
          },
          child: Container(
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
                  child: Icon(categoryIcon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
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
          ),
        );
      },
    );
  }

  // 计算图表Y轴间隔，根据数据范围动态调整
  double _calculateInterval() {
    // 找出最大支出金额，用于设置图表Y轴的最大值
    final maxExpense =
        _dailyExpenses.isEmpty
            ? 300.0 // 默认最大值
            : _dailyExpenses
                .map((spot) => spot.y)
                .reduce((max, y) => max > y ? max : y);

    // 根据要求实现动态间隔：
    // - 0-300元：间隔50元
    // - 300-600元：间隔100元
    // - 600-1200元：间隔200元
    // - 以此类推
    if (maxExpense <= 300) {
      return 50.0;
    } else if (maxExpense <= 600) {
      return 100.0;
    } else if (maxExpense <= 1200) {
      return 200.0;
    } else if (maxExpense <= 2400) {
      return 400.0;
    } else if (maxExpense <= 6000) {
      return 1000.0;
    } else {
      return 2000.0;
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
