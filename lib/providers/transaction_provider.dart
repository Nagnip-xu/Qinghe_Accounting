import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/date_util.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<Transaction> _recentTransactions = [];
  List<Transaction> _transactions = [];
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  bool _isLoading = false;
  String? _error;
  String _currentMonth = DateUtil.getMonthString(DateTime.now());
  bool _hasMoreTransactions = true; // 是否还有更多交易记录
  int _currentPage = 0; // 当前页码
  static const int _pageSize = 10; // 每页记录数量

  // 新增：用于存储特定账户的交易记录
  List<Transaction> _accountTransactions = [];
  bool _isLoadingAccountTransactions = false;

  List<Transaction> get recentTransactions => _recentTransactions;
  List<Transaction> get transactions => _transactions;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentMonth => _currentMonth;
  bool get hasMoreTransactions => _hasMoreTransactions;

  // 新增：获取特定账户交易记录的 getter 和 loading 状态
  List<Transaction> get accountTransactions => _accountTransactions;
  bool get isLoadingAccountTransactions => _isLoadingAccountTransactions;

  // 设置当前月份
  void setCurrentMonth(String month) {
    _currentMonth = month;
    loadMonthlyData();
    notifyListeners();
  }

  // 初始化数据
  Future<void> initData() async {
    _setLoading(true);
    _currentPage = 0; // 重置页码
    _hasMoreTransactions = true; // 重置加载状态
    _recentTransactions = []; // 清空现有数据

    try {
      await _fetchRecentTransactions();
      await loadMonthlyData();
      _setError(null);
    } catch (e) {
      _setError('获取交易数据失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 加载月度数据
  Future<void> loadMonthlyData() async {
    _setLoading(true);

    try {
      await _fetchMonthlyIncome();
      await _fetchMonthlyExpense();
      _setError(null);
    } catch (e) {
      _setError('获取月度数据失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取最近交易记录
  Future<void> _fetchRecentTransactions() async {
    final newTransactions = await _transactionService.getRecentTransactions(
      limit: _pageSize,
    );
    _recentTransactions = newTransactions;
    _currentPage = 1; // 设置当前页为1
    _hasMoreTransactions =
        newTransactions.length == _pageSize; // 如果获取的记录数等于页大小，则可能还有更多
    notifyListeners();
  }

  // 加载更多交易记录
  Future<void> loadMoreRecentTransactions() async {
    if (!_hasMoreTransactions || _isLoading) return;

    _setLoading(true);
    try {
      final newTransactions = await _transactionService.getRecentTransactions(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (newTransactions.isEmpty) {
        _hasMoreTransactions = false;
      } else {
        _recentTransactions.addAll(newTransactions);
        _currentPage++;
        _hasMoreTransactions = newTransactions.length == _pageSize;
      }
      _setError(null);
    } catch (e) {
      _setError('获取更多交易记录失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取所有交易记录
  Future<void> fetchAllTransactions() async {
    _setLoading(true);
    _currentPage = 0; // 重置页码
    _hasMoreTransactions = true; // 重置加载状态
    _transactions = []; // 清空现有数据

    try {
      print('正在获取 $_currentMonth 月份的交易记录...');
      final allTransactions = await _transactionService.getAllTransactions();
      print('获取到总交易记录数: ${allTransactions.length}');

      // 过滤当前月份的交易
      _transactions =
          allTransactions.where((transaction) {
            // 将交易日期格式化为yyyyMM格式
            final transactionMonth = DateUtil.getMonthString(transaction.date);
            final match = transactionMonth == _currentMonth;

            print(
              '交易: ${transaction.id}, 日期: ${transaction.date}, 月份: $transactionMonth, 匹配: $match',
            );

            return match;
          }).toList();

      print('过滤后的交易记录数: ${_transactions.length}');

      // 更新是否还有更多交易的状态
      _hasMoreTransactions = _transactions.length >= 30; // 假设初始加载30条记录

      // 更新月度收支数据
      await loadMonthlyData();

      _setError(null);
    } catch (e) {
      print('获取所有交易记录失败: $e');
      _setError('获取所有交易记录失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取月度收入
  Future<void> _fetchMonthlyIncome() async {
    // 从_currentMonth提取年和月参数(格式为yyyyMM)
    final int year = int.parse(_currentMonth.substring(0, 4));
    final int month = int.parse(_currentMonth.substring(4, 6));
    _monthlyIncome = await _transactionService.getMonthlyIncome(year, month);
    notifyListeners();
  }

  // 获取月度支出
  Future<void> _fetchMonthlyExpense() async {
    // 从_currentMonth提取年和月参数(格式为yyyyMM)
    final int year = int.parse(_currentMonth.substring(0, 4));
    final int month = int.parse(_currentMonth.substring(4, 6));
    _monthlyExpense = await _transactionService.getMonthlyExpense(year, month);
    notifyListeners();
  }

  // 添加交易记录
  Future<bool> addTransaction(
    Transaction transaction, {
    required BuildContext context,
  }) async {
    _setLoading(true);

    try {
      await _transactionService.addTransaction(transaction);

      print("--- [Provider] 交易添加成功，开始同步账户余额 ---");
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      await accountProvider.accountService.syncAccountBalances();
      print("--- [Provider] 账户余额同步完成 ---");

      // 在添加交易后，刷新所有相关数据
      await _fetchRecentTransactions();
      await fetchAllTransactions(); // 确保所有交易列表也刷新
      await loadMonthlyData();

      // 同步账户数据，确保总资产金额正确
      await accountProvider.syncData(); // 刷新 Provider 状态

      _setError(null);
      return true;
    } catch (e) {
      _setError('添加交易记录失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新交易记录
  Future<bool> updateTransaction(
    Transaction transaction, {
    required BuildContext context,
  }) async {
    _setLoading(true);

    try {
      await _transactionService.updateTransaction(transaction);

      print("--- [Provider] 交易更新成功，开始同步账户余额 ---");
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      await accountProvider.accountService.syncAccountBalances();
      print("--- [Provider] 账户余额同步完成 ---");

      await _fetchRecentTransactions();
      await fetchAllTransactions(); // 确保所有交易列表也刷新
      await loadMonthlyData();

      // 同步账户数据，确保总资产金额正确
      await accountProvider.syncData(); // 刷新 Provider 状态

      _setError(null);
      return true;
    } catch (e) {
      _setError('更新交易记录失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除交易记录
  Future<bool> deleteTransaction(
    int id, {
    required BuildContext context,
  }) async {
    _setLoading(true);

    try {
      await _transactionService.deleteTransaction(id);

      print("--- [Provider] 交易删除成功，开始同步账户余额 ---");
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      await accountProvider.accountService.syncAccountBalances();
      print("--- [Provider] 账户余额同步完成 ---");

      await _fetchRecentTransactions();
      await fetchAllTransactions(); // 确保所有交易列表也刷新
      await loadMonthlyData();

      // 同步账户数据，确保总资产金额正确
      await accountProvider.syncData(); // 刷新 Provider 状态

      _setError(null);
      return true;
    } catch (e) {
      _setError('删除交易记录失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 获取按分类的月度支出
  Future<Map<String, double>> getMonthlyExpenseByCategory() async {
    try {
      return await _transactionService.getMonthlyExpenseByCategory(
        _currentMonth,
      );
    } catch (e) {
      _setError('获取分类支出失败：$e');
      return {};
    }
  }

  // 按日期分组的交易记录及收支统计
  Map<String, List<Transaction>> get groupedTransactions {
    final Map<String, List<Transaction>> result = {};

    for (var transaction in _transactions) {
      final dateStr = _formatDateKey(transaction.date);
      if (!result.containsKey(dateStr)) {
        result[dateStr] = [];
      }
      result[dateStr]!.add(transaction);
    }

    return result;
  }

  // 获取日期的总收入和总支出
  Map<String, Map<String, double>> get dailyTotals {
    final Map<String, Map<String, double>> result = {};

    print('计算每日收支统计，交易组数: ${groupedTransactions.length}');

    for (var entry in groupedTransactions.entries) {
      final String dateStr = entry.key;
      final List<Transaction> transactions = entry.value;

      double totalIncome = 0;
      double totalExpense = 0;

      for (var transaction in transactions) {
        print(
          '处理交易: ID ${transaction.id}, 类型 ${transaction.type}, 金额 ${transaction.amount}',
        );

        if (transaction.type == '收入') {
          totalIncome += transaction.amount;
          print('收入: +${transaction.amount}, 累计收入: $totalIncome');
        } else if (transaction.type == '支出') {
          // 支出金额取绝对值，确保总是正数
          totalExpense += transaction.amount.abs();
          print('支出: +${transaction.amount.abs()}, 累计支出: $totalExpense');
        }
        // 转账交易不计入收入或支出
      }

      result[dateStr] = {'income': totalIncome, 'expense': totalExpense};
      print('日期 $dateStr 统计结果: 收入=$totalIncome, 支出=$totalExpense');
    }

    return result;
  }

  // 格式化日期为yyyyMMdd格式，用于分组的key
  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  // 从格式化的key获取日期对象
  DateTime _getDateFromKey(String key) {
    final year = int.parse(key.substring(0, 4));
    final month = int.parse(key.substring(4, 6));
    final day = int.parse(key.substring(6, 8));
    return DateTime(year, month, day);
  }

  // 新增：加载特定账户的交易记录
  Future<void> loadTransactionsForAccount(
    int accountId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoadingAccountTransactions(true);
    try {
      final transactions = await _transactionService.getTransactionsForAccount(
        accountId,
        startDate: startDate,
      );

      // 如果提供了结束日期，在内存中筛选结果
      if (endDate != null) {
        final endDateStr =
            '${DateFormat('yyyy-MM-dd').format(endDate)} 23:59:59';
        final endDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(endDateStr);
        _accountTransactions =
            transactions.where((tx) {
              return tx.date.isBefore(endDateTime) ||
                  tx.date.isAtSameMomentAs(endDateTime);
            }).toList();
      } else {
        _accountTransactions = transactions;
      }

      _setError(null); // 清除之前的错误
    } catch (e) {
      _setError('获取账户交易记录失败: $e');
      _accountTransactions = []; // 出错时清空列表
    } finally {
      _setLoadingAccountTransactions(false);
    }
  }

  // 新增：设置特定账户交易记录的加载状态
  void _setLoadingAccountTransactions(bool loading) {
    if (_isLoadingAccountTransactions == loading) return; // 避免不必要的通知
    _isLoadingAccountTransactions = loading;
    notifyListeners();
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
