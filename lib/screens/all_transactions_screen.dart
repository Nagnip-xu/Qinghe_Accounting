import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';
import '../widgets/date_group_header.dart';
import '../utils/date_util.dart';
import 'transaction_detail_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedMonth = DateUtil.getMonthString(DateTime.now());
  final List<String> _recentMonths = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 获取最近12个月的月份
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _recentMonths.add(DateUtil.getMonthString(month));
    }

    // 添加滚动监听
    _scrollController.addListener(_scrollListener);

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    transactionProvider.setCurrentMonth(_selectedMonth);
    await transactionProvider.fetchAllTransactions();

    setState(() {
      _isLoading = false;
    });
  }

  // 滚动监听函数
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      if (!transactionProvider.isLoading &&
          transactionProvider.hasMoreTransactions) {
        transactionProvider.loadMoreRecentTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全部交易'),
        actions: [
          // 月份选择器
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '选择月份',
            onPressed: () => _showMonthPicker(),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactionProvider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无交易记录',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('刷新'),
                  ),
                ],
              ),
            );
          }

          // 使用按日期分组的交易记录
          final groupedTransactions = transactionProvider.groupedTransactions;
          final dailyTotals = transactionProvider.dailyTotals;

          // 对日期分组的key进行排序（降序，从最近的日期开始）
          final sortedDates =
              groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

          // 构建一个具有月度统计的头部
          final yearMonth = DateUtil.formatMonthForDisplay(_selectedMonth);

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // 月度统计卡片
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$yearMonth收支统计',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            '收入',
                            transactionProvider.monthlyIncome,
                            Colors.green,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          _buildStatItem(
                            context,
                            '支出',
                            transactionProvider.monthlyExpense,
                            Colors.red,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          _buildStatItem(
                            context,
                            '结余',
                            transactionProvider.monthlyIncome -
                                transactionProvider.monthlyExpense,
                            transactionProvider.monthlyIncome >=
                                    transactionProvider.monthlyExpense
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 交易列表
                Expanded(
                  child:
                      sortedDates.isEmpty
                          ? Center(
                            child: Text(
                              '本月暂无交易记录',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: sortedDates.length + 1, // +1 表示底部加载更多区域
                            itemBuilder: (context, index) {
                              // 如果是最后一个元素，显示加载指示器或"已加载全部"
                              if (index == sortedDates.length) {
                                if (transactionProvider.isLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (!transactionProvider
                                    .hasMoreTransactions) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '— 已加载全部数据 —',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox(height: 80);
                                }
                              }

                              final dateStr = sortedDates[index];
                              final transactions =
                                  groupedTransactions[dateStr]!;
                              final totals = dailyTotals[dateStr]!;

                              // 获取此日期的日期对象
                              final year = int.parse(dateStr.substring(0, 4));
                              final month = int.parse(dateStr.substring(4, 6));
                              final day = int.parse(dateStr.substring(6, 8));
                              final date = DateTime(year, month, day);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Column(
                                  children: [
                                    // 日期组标题
                                    DateGroupHeader(
                                      date: date,
                                      income: totals['income']!,
                                      expense: totals['expense']!,
                                    ),

                                    // 该日期的交易记录列表
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.03,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListView.separated(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: transactions.length,
                                        separatorBuilder:
                                            (context, index) => const Divider(
                                              height: 1,
                                              indent: 65,
                                            ),
                                        itemBuilder: (context, idx) {
                                          final transaction = transactions[idx];
                                          return TransactionItem(
                                            transaction: transaction,
                                            onTap: () {
                                              Navigator.of(context)
                                                  .push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              TransactionDetailScreen(
                                                                transaction:
                                                                    transaction,
                                                              ),
                                                    ),
                                                  )
                                                  .then((result) {
                                                    // 如果交易被删除或编辑，刷新数据
                                                    if (result == true) {
                                                      Provider.of<
                                                        AccountProvider
                                                      >(
                                                        context,
                                                        listen: false,
                                                      ).initAccounts();
                                                      _loadData();
                                                    }
                                                  });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建统计项目
  Widget _buildStatItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final formattedAmount = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    ).format(amount);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedAmount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 显示月份选择器
  void _showMonthPicker() {
    // 解析当前选中的年份和月份
    final selectedYear = int.parse(_selectedMonth.substring(0, 4));
    final selectedMonthIndex =
        int.parse(_selectedMonth.substring(4, 6)) - 1; // 0-11

    // 获取所有年份（不重复）
    final Set<int> yearSet =
        _recentMonths.map((month) => int.parse(month.substring(0, 4))).toSet();
    final List<int> years =
        yearSet.toList()..sort((a, b) => b.compareTo(a)); // 降序排列

    int currentYear = selectedYear;
    int currentMonthIndex = selectedMonthIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).primaryColor;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 顶部指示条
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          '选择月份',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 年份选择器
                  Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: years.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final year = years[index];
                        final isSelected = year == currentYear;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              currentYear = year;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? primaryColor
                                      : isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  !isSelected
                                      ? Border.all(
                                        color:
                                            isDarkMode
                                                ? Colors.white24
                                                : Colors.black12,
                                        width: 1,
                                      )
                                      : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$year年',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 月份选择网格
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: 12, // 1-12月
                        itemBuilder: (context, index) {
                          final isCurrentMonth =
                              index == currentMonthIndex &&
                              currentYear == selectedYear;
                          final isSelected = index == currentMonthIndex;

                          // 判断当前月份是否可选（在最近12个月内）
                          final monthStr =
                              currentYear.toString() +
                              (index + 1).toString().padLeft(2, '0');
                          final isAvailable = _recentMonths.contains(monthStr);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  !isAvailable
                                      ? (isDarkMode
                                          ? Colors.white10
                                          : Colors.black.withOpacity(0.03))
                                      : isSelected
                                      ? primaryColor.withOpacity(
                                        isDarkMode ? 0.3 : 0.1,
                                      )
                                      : isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  isSelected && isAvailable
                                      ? Border.all(
                                        color: primaryColor,
                                        width: 2,
                                      )
                                      : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    isAvailable
                                        ? () {
                                          setState(() {
                                            currentMonthIndex = index;
                                          });
                                        }
                                        : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${index + 1}月',
                                        style: TextStyle(
                                          fontSize: isSelected ? 18 : 16,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              !isAvailable
                                                  ? (isDarkMode
                                                      ? Colors.white30
                                                      : Colors.black26)
                                                  : isSelected
                                                  ? primaryColor
                                                  : isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black87,
                                        ),
                                      ),
                                      if (isCurrentMonth)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 底部确认按钮
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // 当前月按钮
                        OutlinedButton.icon(
                          onPressed: () {
                            final now = DateTime.now();
                            final currentMonth = DateUtil.getMonthString(now);
                            if (_recentMonths.contains(currentMonth)) {
                              setState(() {
                                _selectedMonth = currentMonth;
                              });
                              _loadData();
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.today, size: 18),
                          label: const Text('当前月'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 确定按钮
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // 格式化为yyyyMM格式的字符串
                              final monthStr =
                                  currentYear.toString() +
                                  (currentMonthIndex + 1).toString().padLeft(
                                    2,
                                    '0',
                                  );

                              if (_recentMonths.contains(monthStr)) {
                                setState(() {
                                  _selectedMonth = monthStr;
                                });
                                _loadData();
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              '确定',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
