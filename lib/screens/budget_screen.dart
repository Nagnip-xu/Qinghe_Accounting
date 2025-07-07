import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加导入以使用 FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/colors.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../models/budget.dart';
import '../utils/date_util.dart';
import '../utils/formatter.dart';
import '../screens/feature_documentation_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late String _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateUtil.getMonthString(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 标题栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.arrow_back,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '预算管理',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateUtil.formatMonthForDisplay(_currentMonth),
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 预算使用情况
            SliverToBoxAdapter(child: _buildBudgetUsageSection()),

            // 分类预算列表标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '分类预算',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDocumentation(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _showAddBudgetDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 分类预算列表
            _buildCategoryBudgetList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetUsageSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        if (budgetProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final budgetUsage = budgetProvider.budgetUsage;
        if (budgetUsage == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '暂无预算数据',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final totalBudget = budgetUsage['totalBudget'] as double;
        final totalExpense = budgetUsage['totalExpense'] as double;
        final totalPercentage = budgetUsage['totalPercentage'] as double;
        final totalRemaining = budgetUsage['totalRemaining'] as double;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // 总预算卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.wallet,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '月度总预算',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showEditTotalBudgetDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '编辑',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBudgetInfoItem(
                          label: '总预算',
                          amount: totalBudget,
                          color: AppColors.primary,
                        ),
                        _buildBudgetInfoItem(
                          label: '已使用',
                          amount: totalExpense,
                          color: AppColors.expense,
                        ),
                        _buildBudgetInfoItem(
                          label: '剩余',
                          amount: totalRemaining,
                          color: AppColors.income,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '使用进度 ${totalPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalPercentage / 100,
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalPercentage > 100
                            ? AppColors.expense
                            : totalPercentage > 80
                            ? Colors.orange
                            : AppColors.primary,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetInfoItem({
    required String label,
    required double amount,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBudgetList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        if (budgetProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final budgetUsage = budgetProvider.budgetUsage;
        if (budgetUsage == null) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  '暂无预算数据',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        final categoryUsages =
            budgetUsage['categoryUsage'] as List<Map<String, dynamic>>;

        if (categoryUsages.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  '暂无分类预算，请点击"添加"按钮创建',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final categoryUsage = categoryUsages[index];
              return _buildCategoryBudgetCard(categoryUsage);
            }, childCount: categoryUsages.length),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBudgetCard(Map<String, dynamic> categoryUsage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final categoryName = categoryUsage['categoryName'] as String;
    final categoryIcon = categoryUsage['categoryIcon'] as String;
    final categoryColor = categoryUsage['categoryColor'] as String?;
    final budgetAmount = categoryUsage['budgetAmount'] as double;
    final expenseAmount = categoryUsage['expenseAmount'] as double;
    final percentage = categoryUsage['percentage'] as double;
    final remaining = categoryUsage['remaining'] as double;

    // 解析图标
    IconData icon = FontAwesomeIcons.shoppingBag;
    switch (categoryIcon) {
      case 'utensils':
        icon = FontAwesomeIcons.utensils;
        break;
      case 'car':
        icon = FontAwesomeIcons.car;
        break;
      case 'cart-shopping':
        icon = FontAwesomeIcons.cartShopping;
        break;
      case 'film':
        icon = FontAwesomeIcons.film;
        break;
      case 'house':
        icon = FontAwesomeIcons.house;
        break;
      case 'pills':
        icon = FontAwesomeIcons.pills;
        break;
      case 'book':
        icon = FontAwesomeIcons.book;
        break;
      case 'ellipsis':
        icon = FontAwesomeIcons.ellipsis;
        break;
    }

    // 解析颜色
    Color color = AppColors.primary;
    if (categoryColor != null && categoryColor.isNotEmpty) {
      try {
        color = Color(int.parse(categoryColor));
      } catch (e) {
        // 使用默认颜色
      }
    }

    // 进度条颜色
    Color progressColor;
    if (percentage > 100) {
      progressColor = AppColors.expense;
    } else if (percentage > 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppColors.income;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditCategoryBudgetDialog(categoryUsage),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                            isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            percentage > 100
                                ? AppColors.expense
                                : isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '预算: ${CurrencyFormatter.formatWithoutSymbol(budgetAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '已用: ${CurrencyFormatter.formatWithoutSymbol(expenseAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '剩余: ${CurrencyFormatter.formatWithoutSymbol(remaining)}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            remaining < 0
                                ? AppColors.expense
                                : AppColors.income,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage > 100 ? 1 : percentage / 100,
                  backgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTotalBudgetDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 总预算编辑逻辑
    final TextEditingController amountController = TextEditingController();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // 如果已有预算，设置为当前值
    if (budgetProvider.monthlyBudget != null) {
      amountController.text = budgetProvider.monthlyBudget!.amount.toString();
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
            title: Text(
              '设置月度总预算',
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
              ),
            ),
            content: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: '预算金额',
                hintText: '请输入金额',
                prefixText: '¥',
                labelStyle: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
                hintStyle: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary.withOpacity(0.5)
                          : AppColors.textSecondary.withOpacity(0.5),
                ),
                prefixStyle: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (amountController.text.isEmpty) {
                    return;
                  }

                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    return;
                  }

                  final budget = Budget(
                    id: budgetProvider.monthlyBudget?.id ?? '',
                    categoryId: '',
                    categoryName: '月度总预算',
                    amount: amount,
                    period: 'monthly',
                    color: '',
                    icon: 'wallet',
                    month: _currentMonth,
                  );

                  if (budgetProvider.monthlyBudget == null) {
                    budgetProvider.addMonthlyBudget(budget);
                  } else {
                    budgetProvider.updateBudget(budget);
                  }

                  Navigator.pop(context);
                },
                child: const Text(
                  '保存',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditCategoryBudgetDialog(Map<String, dynamic> categoryUsage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 分类预算编辑逻辑
    final TextEditingController amountController = TextEditingController();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // 修复类型转换问题，使用安全的方式处理categoryId
    final categoryId =
        categoryUsage['categoryId'] is int
            ? categoryUsage['categoryId']
            : int.tryParse(categoryUsage['categoryId'].toString()) ?? 0;

    final categoryName = categoryUsage['categoryName'] as String;
    final categoryIcon = categoryUsage['categoryIcon'] as String;
    final categoryColor = categoryUsage['categoryColor'] as String?;
    final budgetAmount = categoryUsage['budgetAmount'] as double;

    amountController.text = budgetAmount.toString();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
            title: Text(
              '设置 $categoryName 预算',
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
              ),
            ),
            content: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: '预算金额',
                labelStyle: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
                hintText: '请输入金额',
                hintStyle: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary.withOpacity(0.5)
                          : AppColors.textSecondary.withOpacity(0.5),
                ),
                prefixText: '¥',
                prefixStyle: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (amountController.text.isEmpty) {
                    return;
                  }

                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    return;
                  }

                  final budget = Budget(
                    id: categoryUsage['id']?.toString() ?? '',
                    categoryId: categoryId.toString(),
                    categoryName: categoryName,
                    amount: amount,
                    period: 'monthly',
                    color: categoryColor ?? '',
                    icon: categoryIcon,
                    month: _currentMonth,
                  );

                  budgetProvider.updateBudget(budget);
                  Navigator.pop(context);
                },
                child: const Text(
                  '保存',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddBudgetDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 显示添加预算对话框
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final categories = categoryProvider.expenseCategories;
    TextEditingController amountController = TextEditingController();
    String? selectedCategoryId;

    // 检查是否有可用的分类
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先添加支出分类'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 初始化选中的分类ID为第一个分类，转换为字符串
    selectedCategoryId = categories.first.id.toString();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
              title: Text(
                '添加预算分类',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 分类选择下拉框
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '选择分类',
                      labelStyle: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    dropdownColor:
                        isDarkMode ? AppColors.darkSurface : Colors.white,
                    value: selectedCategoryId,
                    items:
                        categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id.toString(),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // 预算金额输入框
                  TextField(
                    controller: amountController,
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: '预算金额',
                      labelStyle: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // 验证输入
                    if (selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请选择分类'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请输入预算金额'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    try {
                      // 获取选中的分类信息
                      final category = categories.firstWhere(
                        (c) => c.id.toString() == selectedCategoryId,
                      );

                      // 创建预算对象
                      final budget = Budget(
                        id: '', // ID会在添加时由数据库生成
                        categoryId: category.id.toString(),
                        categoryName: category.name,
                        amount: double.parse(amountController.text),
                        period: 'monthly',
                        color: category.color,
                        icon: category.icon,
                        month: _currentMonth,
                      );

                      // 添加预算
                      final result = await budgetProvider.addCategoryBudget(
                        budget,
                      );

                      if (result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('预算添加成功'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(dialogContext);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('预算添加失败'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('添加预算时出错: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    '保存',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDocumentation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const FeatureDocumentationScreen(featureId: 'category_budget'),
      ),
    );
  }
}
