import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/transaction_item.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/formatter.dart';
import '../utils/date_util.dart';
import '../screens/all_transactions_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../models/transaction.dart';
import '../widgets/date_group_header.dart';

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

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).initAccounts();
      Provider.of<TransactionProvider>(context, listen: false).initData().then((
        _,
      ) {
        // 数据加载完成后启动动画
        _animationController.forward();
      });
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
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
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

          // 先强制同步所有账户余额
          final accountProvider = Provider.of<AccountProvider>(
            context,
            listen: false,
          );
          await accountProvider.accountService.syncAccountBalances();

          // 再同步账户数据
          await accountProvider.syncData();

          // 刷新交易数据
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).initData();

          // 重新播放动画
          _animationController.forward();
        },
        child: CustomScrollView(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.black.withOpacity(0.1),
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
                                          ? userProvider.currentUser.username[0]
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.recentTransactions ?? '最近交易',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // 查看所有交易
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const AllTransactionsScreen(),
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          l10n?.viewAll ?? '查看全部',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 加载指示器或空状态
            if (transactionProvider.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (transactionProvider.recentTransactions.isEmpty)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
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
                            l10n?.noTransactions ?? '暂无交易记录',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            // 交易记录列表
            else
              _buildTransactionsList(transactionProvider, accountProvider),

            // 底部加载指示器
            SliverToBoxAdapter(
              child:
                  transactionProvider.isLoading &&
                          transactionProvider.recentTransactions.isNotEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      : !transactionProvider.hasMoreTransactions &&
                          transactionProvider.recentTransactions.isNotEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: Text(
                            l10n?.loadedAllData ?? '— 已加载全部数据 —',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white38
                                      : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      : const SizedBox(height: 80), // 底部安全间距
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
                      transactionProvider.monthlyIncome,
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
                      transactionProvider.monthlyExpense,
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

  // 重新添加 _buildIncomeExpenseItem 方法
  Widget _buildIncomeExpenseItem(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String label,
    double amount,
  ) {
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
                            TransactionItem(
                              transaction: transaction,
                              onTap: () {
                                Navigator.of(context)
                                    .push(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => TransactionDetailScreen(
                                              transaction: transaction,
                                            ),
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          const begin = Offset(0.0, 1.0);
                                          const end = Offset.zero;
                                          const curve = Curves.easeInOut;

                                          var tween = Tween(
                                            begin: begin,
                                            end: end,
                                          ).chain(CurveTween(curve: curve));

                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    )
                                    .then((result) {
                                      // 如果交易被删除或编辑，刷新数据
                                      if (result == true) {
                                        print("交易详情页返回，进行全面数据刷新");
                                        // 先强制同步账户余额
                                        accountProvider.accountService
                                            .syncAccountBalances()
                                            .then((_) {
                                              // 然后刷新账户数据
                                              accountProvider.syncData().then((
                                                _,
                                              ) {
                                                // 最后刷新交易列表
                                                transactionProvider.initData();
                                              });
                                            });
                                      }
                                    });
                              },
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
