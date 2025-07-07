import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/date_util.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // 导入navigatorKey

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService;

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
  Map<int, List<Transaction>> _accountTransactions = {};
  bool _isLoadingAccountTransactions = false;

  TransactionProvider({TransactionService? transactionService})
    : _transactionService = transactionService ?? TransactionService();

  List<Transaction> get recentTransactions => _recentTransactions;
  List<Transaction> get transactions => _transactions;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentMonth => _currentMonth;
  bool get hasMoreTransactions => _hasMoreTransactions;

  // 提供对交易服务的访问
  TransactionService get transactionService => _transactionService;

  // 新增：获取特定账户交易记录的 getter 和 loading 状态
  List<Transaction> get accountTransactions =>
      _accountTransactions.values.expand((e) => e).toList();
  bool get isLoadingAccountTransactions => _isLoadingAccountTransactions;

  // 设置当前月份
  Future<void> setCurrentMonth(String month) async {
    print("[CRITICAL] 设置当前月份: 从 $_currentMonth 变为 $month");

    // 存储原始月份格式以用于调试
    final oldMonth = _currentMonth;
    _currentMonth = month;

    // 无论月份是否变化，都强制重新加载数据
    print("[CRITICAL] 重新加载月份 $month 的数据");
    notifyListeners(); // 先通知月份变化

    // 强制加载该月份的数据
    await loadMonthlyData();
    await fetchAllTransactions();

    print("[CRITICAL] 月份 $month 的数据加载完成");
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
    print("[CRITICAL] 开始加载月度数据: 当前月份=$_currentMonth");
    _setLoading(true);

    try {
      // 确保_currentMonth的格式正确(格式为yyyyMM)
      if (_currentMonth.length != 6) {
        print("[CRITICAL ERROR] 月份格式错误: $_currentMonth，应为yyyyMM格式");
        _setError('月份格式错误');
        return;
      }

      final int year = int.parse(_currentMonth.substring(0, 4));
      final int month = int.parse(_currentMonth.substring(4, 6));

      print("[CRITICAL] 解析月份: $_currentMonth -> 年:$year, 月:$month");

      // 首先进行调试，打印该月份的所有交易记录
      await _transactionService.debugPrintMonthTransactions(year, month);

      // 直接调用service方法获取月度收入和支出
      double income = 0.0;
      double expense = 0.0;

      try {
        income = await _transactionService.getMonthlyIncome(year, month);
        print("[CRITICAL] 获取到月度收入: $income");
      } catch (e) {
        print("[CRITICAL ERROR] 获取月度收入失败: $e");
        income = 0.0;
      }

      try {
        expense = await _transactionService.getMonthlyExpense(year, month);
        print("[CRITICAL] 获取到月度支出: $expense");
      } catch (e) {
        print("[CRITICAL ERROR] 获取月度支出失败: $e");
        expense = 0.0;
      }

      // 更新数据，确保数据合法
      _monthlyIncome = income.isNaN ? 0.0 : income;
      _monthlyExpense = expense.isNaN ? 0.0 : expense;

      print("[CRITICAL] 月度数据更新完成: 收入=$_monthlyIncome, 支出=$_monthlyExpense");

      _setError(null);

      // 每次都通知监听器更新UI
      notifyListeners();
    } catch (e) {
      print("[CRITICAL ERROR] 获取月度数据失败: $e");
      print(e.toString());
      _setError('获取月度数据失败：$e');

      // 确保在失败时仍然有合法值
      _monthlyIncome = 0.0;
      _monthlyExpense = 0.0;

      // 即使出错也通知UI更新
      notifyListeners();
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

      // 从_currentMonth提取年和月，确保格式正确
      if (_currentMonth.length != 6) {
        print("月份格式错误: $_currentMonth，应为yyyyMM格式");
        return;
      }

      final int year = int.parse(_currentMonth.substring(0, 4));
      final int month = int.parse(_currentMonth.substring(4, 6));
      final String yearMonthFormatted =
          "$year-${month.toString().padLeft(2, '0')}";

      // 直接查询该月份的交易
      final allTransactions = await _transactionService.getAllTransactions();
      print('获取到总交易记录数: ${allTransactions.length}');

      // 过滤当前月份的交易，确保日期比较正确
      _transactions =
          allTransactions.where((transaction) {
            final transactionDate = transaction.date;
            final transactionYearMonth =
                "${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}";
            final match = transactionYearMonth == yearMonthFormatted;

            print(
              '交易: ${transaction.id}, 日期: ${transaction.date}, 月份: $transactionYearMonth, 匹配: $match',
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

  // 获取指定账户的所有交易记录
  Future<void> fetchTransactionsByAccount(int accountId) async {
    _setLoading(true);
    try {
      final accountTransactions = await _transactionService
          .getTransactionsByAccount(accountId);
      _accountTransactions[accountId] = accountTransactions;
      _setError(null);
    } catch (e) {
      _setError('获取账户交易记录失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取已加载的指定账户的交易记录
  List<Transaction> getAccountTransactions(int accountId) {
    return _accountTransactions[accountId] ?? [];
  }

  // 添加交易
  Future<bool> addTransaction(
    Transaction transaction, {
    BuildContext? context,
  }) async {
    print("[CRITICAL] 开始添加交易: ${transaction.type}, 金额: ${transaction.amount}");
    _setLoading(true);

    try {
      // 添加交易到数据库
      await _transactionService.addTransaction(transaction);
      print("[CRITICAL] 交易添加成功，ID: ${transaction.id}");

      // 如果提供了context，就使用AccountProvider同步账户余额
      if (context != null) {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        print("[CRITICAL] 开始同步账户余额");
        await accountProvider.accountService.syncAccountBalances();
        print("[CRITICAL] 账户余额同步完成");

        // 同步账户数据，确保总资产金额正确
        await accountProvider.syncData();
      }

      // 先获取交易的年月
      final transactionMonth = DateUtil.getMonthString(transaction.date);
      print("[CRITICAL] 交易日期: ${transaction.date}, 月份: $transactionMonth");

      // 优先刷新交易列表，确保UI显示最新交易
      await _fetchRecentTransactions();

      // 如果交易月份与当前月份相同，需要更新月度统计
      if (transactionMonth == _currentMonth) {
        print("[CRITICAL] 交易月份匹配当前月份，更新月度统计");
        // 立即刷新月度数据 - 确保统计数据与交易列表一致
        await loadMonthlyData();
      } else {
        print("[CRITICAL] 交易月份不匹配当前月份，不更新月度统计");
      }

      // 确保所有交易列表数据更新
      await fetchAllTransactions();

      _setError(null);
      return true;
    } catch (e) {
      // 特别处理余额不足的错误
      if (e.toString().contains('余额不足') || e.toString().contains('无法完成交易')) {
        _setError('账户余额不足，无法完成交易');
      } else {
        _setError('添加交易失败: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新交易
  Future<bool> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction, {
    BuildContext? context,
  }) async {
    _setLoading(true);

    try {
      // 验证操作是否会导致余额不足
      await _transactionService.updateTransaction(
        oldTransaction,
        newTransaction,
      );

      // 如果提供了context，就使用AccountProvider同步账户余额
      if (context != null) {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        print("--- [Provider] 交易更新成功，开始同步账户余额 ---");
        await accountProvider.accountService.syncAccountBalances();
        print("--- [Provider] 账户余额同步完成 ---");

        // 同步账户数据，确保总资产金额正确
        await accountProvider.syncData();
      }

      // 立即刷新交易和月度数据
      await _fetchRecentTransactions();
      await loadMonthlyData();
      await fetchAllTransactions();

      // 强制重新计算月度收入和支出
      if (_currentMonth.isNotEmpty) {
        final int year = int.parse(_currentMonth.substring(0, 4));
        final int month = int.parse(_currentMonth.substring(4, 6));

        _monthlyIncome = await _transactionService.getMonthlyIncome(
          year,
          month,
        );
        _monthlyExpense = await _transactionService.getMonthlyExpense(
          year,
          month,
        );
        notifyListeners();
      }

      // 更新可能受影响的账户交易列表
      final accountIds = <int>{
        oldTransaction.accountId,
        newTransaction.accountId,
      };
      if (oldTransaction.toAccountId != null) {
        accountIds.add(oldTransaction.toAccountId!);
      }
      if (newTransaction.toAccountId != null) {
        accountIds.add(newTransaction.toAccountId!);
      }

      for (final accountId in accountIds) {
        if (_accountTransactions.containsKey(accountId)) {
          await fetchTransactionsByAccount(accountId);
        }
      }

      _setError(null);
      return true;
    } catch (e) {
      // 特别处理余额不足的错误
      if (e.toString().contains('余额不足') || e.toString().contains('无法完成交易')) {
        _setError('账户余额不足，无法完成交易更新');
      } else {
        _setError('更新交易失败: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除交易
  Future<bool> deleteTransaction(
    dynamic transactionOrId, {
    BuildContext? context,
  }) async {
    _setLoading(true);
    try {
      Transaction transaction;

      // 处理兼容性：如果传入的是int类型的ID而不是Transaction对象
      if (transactionOrId is int) {
        final id = transactionOrId;
        final transactionObj = await _transactionService.getTransaction(id);
        if (transactionObj == null) {
          throw Exception('找不到要删除的交易');
        }
        transaction = transactionObj;
      } else if (transactionOrId is Transaction) {
        transaction = transactionOrId;
      } else {
        throw ArgumentError('参数必须是Transaction对象或整数ID');
      }

      await _transactionService.deleteTransaction(transaction);

      // 如果提供了context，就使用AccountProvider同步账户余额
      if (context != null) {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        print("--- [Provider] 交易删除成功，开始同步账户余额 ---");
        await accountProvider.accountService.syncAccountBalances();
        print("--- [Provider] 账户余额同步完成 ---");

        // 同步账户数据，确保总资产金额正确
        await accountProvider.syncData();
      }

      // 立即刷新交易和月度数据
      await _fetchRecentTransactions();
      await loadMonthlyData();
      await fetchAllTransactions();

      // 更新可能受影响的账户交易列表
      final accountIds = <int>{transaction.accountId};
      if (transaction.toAccountId != null) {
        accountIds.add(transaction.toAccountId!);
      }

      for (final accountId in accountIds) {
        if (_accountTransactions.containsKey(accountId)) {
          await fetchTransactionsByAccount(accountId);
        }
      }

      _setError(null);
      return true;
    } catch (e) {
      _setError('删除交易失败: $e');
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

  // 批量删除交易
  Future<bool> deleteTransactions(
    List<dynamic> transactionIds, {
    BuildContext? context,
  }) async {
    _setLoading(true);
    bool allSuccess = true;

    try {
      // 遍历所有交易ID逐个删除
      for (final transactionId in transactionIds) {
        try {
          final success = await deleteTransaction(transactionId);
          if (!success) {
            allSuccess = false;
            print('删除交易失败, ID: $transactionId');
          }
        } catch (e) {
          allSuccess = false;
          print('删除交易时出错, ID: $transactionId, 错误: $e');
        }
      }

      // 如果提供了context，就使用AccountProvider同步账户余额
      if (context != null) {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        print("--- [Provider] 批量交易删除完成，开始同步账户余额 ---");
        await accountProvider.accountService.syncAccountBalances();
        print("--- [Provider] 账户余额同步完成 ---");

        // 同步账户数据，确保总资产金额正确
        await accountProvider.syncData();
      }

      // 立即刷新交易和月度数据
      await _fetchRecentTransactions();
      await loadMonthlyData();
      await fetchAllTransactions();

      _setError(null);
      return allSuccess;
    } catch (e) {
      _setError('批量删除交易失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
