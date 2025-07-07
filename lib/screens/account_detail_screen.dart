import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatter.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  // 用于存储按日期分组的交易记录
  Map<String, List<Transaction>> _groupedTransactions = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    // 加载该账户的所有交易记录
    await transactionProvider.fetchTransactionsByAccount(widget.account.id!);

    if (mounted) {
      final transactions = transactionProvider.getAccountTransactions(
        widget.account.id!,
      );

      // 按日期分组交易记录
      final grouped = <String, List<Transaction>>{};
      for (var transaction in transactions) {
        final dateStr = _getDateKey(transaction.date);
        if (!grouped.containsKey(dateStr)) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(transaction);
      }

      setState(() {
        _transactions = transactions;
        _groupedTransactions = grouped;
        _isLoading = false;
      });
    }
  }

  // 获取日期键值
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 格式化日期显示
  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == yesterday) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        widget.account.balance < 0 ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        elevation: 0,
        title: Text(
          widget.account.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18),
          color: isDarkMode ? Colors.white70 : Colors.black54,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 账户信息卡片
          _buildAccountInfoCard(isDarkMode, themeColor),

          // 交易列表标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '交易记录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '共 ${_transactions.length} 条',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 交易列表
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : _buildGroupedTransactionsList(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无交易记录',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(bool isDarkMode, Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 账户图标和名称
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAccountIcon(widget.account.icon),
                  color: themeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.account.isDebt ? '负债账户' : '资产账户',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.account.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 余额显示
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account.isDebt ? '当前负债' : '当前余额',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(widget.account.balance),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTransactionsList(bool isDarkMode) {
    // 按日期排序的键
    final sortedDates =
        _groupedTransactions.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // 降序排列，最近日期在前

    return ListView.builder(
      itemCount: sortedDates.length,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final transactions = _groupedTransactions[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期标题
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
              child: Text(
                _formatDateHeader(dateKey),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ),

            // 该日期下的交易记录
            ...transactions
                .map(
                  (transaction) =>
                      _buildTransactionItem(transaction, isDarkMode),
                )
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction, bool isDarkMode) {
    // 判断收支类型，设置颜色和图标
    Color amountColor;
    IconData transactionIcon;

    switch (transaction.type) {
      case '收入':
        amountColor = AppColors.income;
        transactionIcon = Icons.arrow_upward;
        break;
      case '支出':
        amountColor = AppColors.expense;
        transactionIcon = Icons.arrow_downward;
        break;
      case '转账':
        amountColor = Colors.purple;
        transactionIcon = Icons.swap_horiz;
        break;
      case '调整':
        amountColor = Colors.grey;
        transactionIcon = Icons.tune;
        break;
      default:
        amountColor = AppColors.textSecondary;
        transactionIcon = Icons.attach_money;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 4.0,
        ),
        minLeadingWidth: 36,
        leading: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: amountColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(transactionIcon, color: amountColor, size: 16),
        ),
        title: Row(
          children: [
            Text(
              transaction.categoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            if (transaction.type == '转账' && transaction.toAccountName != null)
              Text(
                ' → ${transaction.toAccountName}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                ),
              ),
          ],
        ),
        subtitle:
            transaction.note?.isNotEmpty == true
                ? Text(
                  transaction.note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.type == '支出'
                  ? '-${CurrencyFormatter.format(transaction.amount)}'
                  : CurrencyFormatter.format(transaction.amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTransactionTime(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTransactionTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getAccountIcon(String? iconName) {
    switch (iconName) {
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'mobile-screen':
        return Icons.smartphone_outlined;
      case 'credit-card':
        return Icons.credit_card_outlined;
      case 'money-bill-trend-up':
        return Icons.trending_up_outlined;
      case 'wechat':
        return Icons.chat_bubble_outline;
      case 'alipay':
        return Icons.account_balance_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}
