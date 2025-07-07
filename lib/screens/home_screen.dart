import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/transaction_item.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/formatter.dart';
import '../utils/date_util.dart';
import '../utils/toast_message.dart';
import '../screens/all_transactions_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../models/transaction.dart';
import '../widgets/date_group_header.dart';
import 'package:flutter/foundation.dart';
import '../services/data_sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isAmountVisible = true; // 添加金额可见性状态变量
  bool _dataLoaded = false; // 只需一个简单标志

  // 多选模式相关变量
  bool _isMultiSelectMode = false;
  final Set<int> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 添加滚动监听，实现滚动到底部加载更多功能
    _scrollController.addListener(_scrollListener);

    // 初始化数据 - 只加载一次
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeData();
    });
  }

  // 新增：初始化和刷新所有数据的方法
  Future<void> _initializeData() async {
    print("[CRITICAL] 首页开始初始化数据");
    // 先初始化账户
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    await accountProvider.initAccounts();

    // 强制同步账户余额，确保所有账户余额正确
    await accountProvider.accountService.syncAccountBalances();

    // 同步账户数据，确保总资产正确
    await accountProvider.syncData();

    // 设置当前月份并加载数据
    final now = DateTime.now();
    final currentMonth = DateUtil.getMonthString(now);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    print("[CRITICAL] 开始加载交易数据，当前月份: $currentMonth");

    // 先初始化交易数据
    await transactionProvider.initData();

    // 设置当前月份并刷新月度收入支出数据
    await transactionProvider.setCurrentMonth(currentMonth);

    // 确保月度数据正确加载
    await transactionProvider.loadMonthlyData();

    print("[CRITICAL] 首页数据初始化完成");

    // 标记数据已加载
    setState(() {
      _dataLoaded = true;
    });

    // 数据加载完成后启动动画
    _animationController.forward();
  }

  // 完全重写didChangeDependencies，极度简化
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 不做任何数据加载，避免重复刷新
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
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 切换多选模式
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedTransactionIds.clear();
      }
    });
  }

  // 选择/取消选择交易
  void _toggleTransactionSelection(int transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
      } else {
        _selectedTransactionIds.add(transactionId);
      }

      // 如果没有选中任何交易，自动退出多选模式
      if (_selectedTransactionIds.isEmpty && _isMultiSelectMode) {
        _isMultiSelectMode = false;
      }
    });
  }

  // 批量删除选中的交易
  Future<void> _deleteSelectedTransactions() async {
    if (_selectedTransactionIds.isEmpty) {
      return;
    }

    // 确认删除对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text(
              '确定要删除选中的${_selectedTransactionIds.length}个交易记录吗？此操作不可撤销。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirm != true) {
      return;
    }

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      final List<int> idsToDelete = _selectedTransactionIds.toList();

      // 显示加载中提示
      ToastMessage.show(
        context,
        '正在删除${idsToDelete.length}个交易...',
        icon: Icons.delete,
        backgroundColor: Colors.blue.withOpacity(0.9),
      );

      // 批量删除交易
      final success = await transactionProvider.deleteTransactions(
        idsToDelete,
        context: context,
      );

      if (success) {
        ToastMessage.show(
          context,
          '删除成功',
          icon: Icons.check_circle,
          backgroundColor: Colors.green.withOpacity(0.9),
        );
      } else {
        ToastMessage.show(
          context,
          '部分或全部删除失败',
          icon: Icons.error,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }

      // 刷新数据
      await accountProvider.syncData();
      await transactionProvider.initData();

      // 退出多选模式
      setState(() {
        _isMultiSelectMode = false;
        _selectedTransactionIds.clear();
      });
    } catch (e) {
      ToastMessage.show(
        context,
        '删除失败: $e',
        icon: Icons.error,
        backgroundColor: Colors.red.withOpacity(0.9),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = AppLocalizations.of(context);

    // 当前日期
    final now = DateTime.now();
    final today = DateFormat('yyyy年MM月dd日').format(now);
    final weekday = DateUtil.getWeekday(now);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // 重置动画
          _animationController.reset();

          try {
            // 调用统一的数据初始化方法，确保所有数据一致刷新
            await _initializeData();

            // 退出多选模式
            setState(() {
              _isMultiSelectMode = false;
              _selectedTransactionIds.clear();
            });

            // 显示刷新成功提示
            ToastMessage.show(
              context,
              '数据已刷新',
              icon: Icons.check_circle_outline,
              backgroundColor: Colors.green.withOpacity(0.9),
            );
          } catch (e) {
            print('刷新数据出错: $e');
            ToastMessage.show(
              context,
              '刷新失败: ${e.toString().substring(0, e.toString().length > 50 ? 50 : e.toString().length)}...',
              icon: Icons.error_outline,
              backgroundColor: Colors.red.withOpacity(0.9),
            );
          }
        },
        child: Stack(
          children: [
            // 主内容
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              slivers: [
                // 顶部应用栏
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  // 在多选模式下显示操作按钮
                  leading:
                      _isMultiSelectMode
                          ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleMultiSelectMode,
                          )
                          : null,
                  actions:
                      _isMultiSelectMode
                          ? [
                            // 在多选模式下显示选中数量
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Text(
                                  '已选择 ${_selectedTransactionIds.length} 项',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ]
                          : null,
                  flexibleSpace: FlexibleSpaceBar(
                    background: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 用户信息
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n?.hello ?? '你好'}，${userProvider.isLoggedIn ? userProvider.currentUser.username : l10n?.user ?? '用户'}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${l10n?.today ?? '今天是'} $today $weekday',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Hero(
                                    tag: 'userAvatar',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white24,
                                        child: Text(
                                          userProvider.isLoggedIn
                                              ? userProvider
                                                  .currentUser
                                                  .username[0]
                                                  .toUpperCase()
                                              : '用',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildAssetCard(
                                  context,
                                  accountProvider,
                                  transactionProvider,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 最近交易标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '最近交易',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            // 多选切换按钮
                            if (!_isMultiSelectMode)
                              TextButton(
                                onPressed: () => _toggleMultiSelectMode(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                child: const Text('多选'),
                              ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const AllTransactionsScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              child: const Text('查看全部'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 交易加载指示器
                if (transactionProvider.isLoading &&
                    transactionProvider.recentTransactions.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                // 无交易记录显示
                else if (transactionProvider.recentTransactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          '暂无交易记录',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  )
                // 交易记录列表
                else
                  _buildTransactionsList(transactionProvider, accountProvider),

                // 底部填充
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),

            // 多选模式下的底部操作栏
            if (_isMultiSelectMode)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedTransactionIds.clear();
                            });
                          },
                          icon: const Icon(Icons.select_all),
                          label: const Text('取消全选'),
                        ),
                        TextButton.icon(
                          onPressed: _deleteSelectedTransactions,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            '删除选择',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 构建资产卡片
  Widget _buildAssetCard(
    BuildContext context,
    AccountProvider accountProvider,
    TransactionProvider transactionProvider,
  ) {
    final l10n = AppLocalizations.of(context);

    // 只保留一条调试日志，减少输出
    if (kDebugMode) {
      print(
        "[HomeScreen] 资产卡片: 收入=${transactionProvider.monthlyIncome}，支出=${transactionProvider.monthlyExpense}",
      );
    }

    final monthlyIncome = transactionProvider.monthlyIncome;
    final monthlyExpense = transactionProvider.monthlyExpense;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animationController.value)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n?.totalAssets ?? '总资产',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isAmountVisible = !_isAmountVisible;
                        });
                      },
                      child: Icon(
                        _isAmountVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 14,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 简化刷新按钮
                    InkWell(
                      onTap: () async {
                        // 重置动画效果
                        _animationController.reset();

                        // 获取providers
                        final transactionProvider =
                            Provider.of<TransactionProvider>(
                              context,
                              listen: false,
                            );

                        final accountProvider = Provider.of<AccountProvider>(
                          context,
                          listen: false,
                        );

                        // 强制同步账户余额
                        await accountProvider.accountService
                            .syncAccountBalances();

                        // 同步账户数据
                        await accountProvider.syncData();

                        // 使用公开方法重新加载数据
                        await transactionProvider.initData();

                        // 确保月度收入支出数据刷新
                        await transactionProvider.loadMonthlyData();

                        // 重新播放动画
                        _animationController.forward();

                        // 提示用户
                        ToastMessage.show(
                          context,
                          '数据已刷新',
                          icon: Icons.check_circle_outline,
                          backgroundColor: Colors.green.withOpacity(0.9),
                        );
                      },
                      child: Icon(
                        Icons.refresh,
                        size: 14,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isAmountVisible
                      ? CurrencyFormatter.format(accountProvider.totalAssets)
                      : '******',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIncomeExpenseItem(
                      context,
                      Icons.arrow_upward,
                      Colors.green,
                      l10n?.income ?? '收入',
                      monthlyIncome,
                    ),
                    SizedBox(
                      height: 30,
                      child: VerticalDivider(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                    _buildIncomeExpenseItem(
                      context,
                      Icons.arrow_downward,
                      Colors.red,
                      l10n?.expense ?? '支出',
                      monthlyExpense,
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

  // 优化收支项目构建方法
  Widget _buildIncomeExpenseItem(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String label,
    double amount,
  ) {
    // 移除频繁的调试日志，避免大量输出
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _isAmountVisible
                      ? CurrencyFormatter.format(amount)
                      : '******',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建交易记录列表
  Widget _buildTransactionsList(
    TransactionProvider transactionProvider,
    AccountProvider accountProvider,
  ) {
    // 获取最近的交易，按日期分组
    final recentTransactions = transactionProvider.recentTransactions;

    // 创建临时Map存储按日期分组的交易
    final Map<String, List<Transaction>> tempGrouped = {};
    final Map<String, Map<String, double>> tempTotals = {};

    // 按日期分组最近的交易
    for (var transaction in recentTransactions) {
      final dateStr =
          '${transaction.date.year}${transaction.date.month.toString().padLeft(2, '0')}${transaction.date.day.toString().padLeft(2, '0')}';
      if (!tempGrouped.containsKey(dateStr)) {
        tempGrouped[dateStr] = [];
        tempTotals[dateStr] = {'income': 0.0, 'expense': 0.0};
      }
      tempGrouped[dateStr]!.add(transaction);

      // 计算每日收支
      if (transaction.type == '收入') {
        tempTotals[dateStr]!['income'] =
            (tempTotals[dateStr]!['income'] ?? 0.0) + transaction.amount.abs();
      } else if (transaction.type == '支出') {
        tempTotals[dateStr]!['expense'] =
            (tempTotals[dateStr]!['expense'] ?? 0.0) + transaction.amount.abs();
      } else if (transaction.type == '转账') {
        // 转账不计入收入或支出
      }
    }

    // 对日期分组的key进行排序（降序，从最近的日期开始）
    final sortedDates =
        tempGrouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // 构建SliverList
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateStr = sortedDates[index];
        final transactions = tempGrouped[dateStr]!;
        final totals = tempTotals[dateStr]!;

        // 获取此日期的日期对象
        final year = int.parse(dateStr.substring(0, 4));
        final month = int.parse(dateStr.substring(4, 6));
        final day = int.parse(dateStr.substring(6, 8));
        final date = DateTime(year, month, day);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.4 + 0.05 * index,
                  1.0,
                  curve: Curves.easeOutQuart,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16).copyWith(
                bottom:
                    index == sortedDates.length - 1 ? 16.0 : 0, // 为最后一个元素添加底部间距
              ),
              child: Column(
                children: [
                  // 日期组标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: DateGroupHeader(
                      date: date,
                      income: totals['income']!,
                      expense: totals['expense']!,
                    ),
                  ),

                  // 该日期的交易记录列表
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(transactions.length, (idx) {
                        final transaction = transactions[idx];
                        return Column(
                          children: [
                            if (idx > 0)
                              Divider(
                                height: 1,
                                indent: 65,
                                endIndent: 0,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            // 添加长按事件用于触发多选模式
                            GestureDetector(
                              onLongPress: () {
                                if (!_isMultiSelectMode) {
                                  setState(() {
                                    _isMultiSelectMode = true;
                                    _selectedTransactionIds.add(
                                      transaction.id!,
                                    );
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  // 多选模式下显示复选框
                                  if (_isMultiSelectMode)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Checkbox(
                                        value: _selectedTransactionIds.contains(
                                          transaction.id,
                                        ),
                                        onChanged: (value) {
                                          _toggleTransactionSelection(
                                            transaction.id!,
                                          );
                                        },
                                      ),
                                    ),
                                  // 交易项
                                  Expanded(
                                    child: TransactionItem(
                                      transaction: transaction,
                                      onTap:
                                          _isMultiSelectMode
                                              ? () =>
                                                  _toggleTransactionSelection(
                                                    transaction.id!,
                                                  )
                                              : () {
                                                Navigator.of(context)
                                                    .push(
                                                      PageRouteBuilder(
                                                        pageBuilder:
                                                            (
                                                              context,
                                                              animation,
                                                              secondaryAnimation,
                                                            ) => TransactionDetailScreen(
                                                              transaction:
                                                                  transaction,
                                                            ),
                                                        transitionsBuilder: (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child,
                                                        ) {
                                                          const begin = Offset(
                                                            0.0,
                                                            1.0,
                                                          );
                                                          const end =
                                                              Offset.zero;
                                                          const curve =
                                                              Curves.easeInOut;

                                                          var tween = Tween(
                                                            begin: begin,
                                                            end: end,
                                                          ).chain(
                                                            CurveTween(
                                                              curve: curve,
                                                            ),
                                                          );

                                                          return SlideTransition(
                                                            position: animation
                                                                .drive(tween),
                                                            child: child,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                    .then((result) {
                                                      // 如果交易被删除或编辑，刷新数据
                                                      if (result == true) {
                                                        print(
                                                          "交易详情页返回，进行全面数据刷新",
                                                        );

                                                        // 使用DataSyncService进行全面数据同步
                                                        final dataSync =
                                                            DataSyncService();
                                                        dataSync
                                                            .syncTransactionRelatedData(
                                                              context,
                                                            );
                                                      }
                                                    });
                                              },
                                      onLongPress: () {
                                        if (!_isMultiSelectMode) {
                                          setState(() {
                                            _isMultiSelectMode = true;
                                            _selectedTransactionIds.add(
                                              transaction.id!,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }, childCount: sortedDates.length),
    );
  }
}
