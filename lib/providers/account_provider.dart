import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/account_service.dart';

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();

  List<Account> _accounts = [];
  double _totalAssets = 0.0;
  bool _isLoading = false;
  String? _error;

  List<Account> get accounts => _accounts;
  double get totalAssets => _totalAssets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 获取账户服务实例
  AccountService get accountService => _accountService;

  // 初始化账户数据
  Future<void> initAccounts() async {
    _setLoading(true);

    try {
      // 检查是否需要添加默认账户
      await _checkAndAddDefaultAccounts();

      await _fetchAccounts();
      await _fetchTotalAssets();
      _setError(null);
    } catch (e) {
      _setError('获取账户数据失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 检查并添加默认账户（如果账户表为空）
  Future<void> _checkAndAddDefaultAccounts() async {
    final accounts = await _accountService.getAllAccounts();
    if (accounts.isEmpty) {
      print('账户表为空，添加默认账户');
      // 添加现金钱包
      await _accountService.addAccount(
        Account(
          name: '现金钱包',
          type: '现金',
          balance: 0.0,
          icon: 'wallet',
          color: '0xFF4CAF50',
        ),
      );

      // 添加微信钱包
      await _accountService.addAccount(
        Account(
          name: '微信钱包',
          type: '电子钱包',
          balance: 0.0,
          icon: 'mobile-screen',
          color: '0xFF07C160',
        ),
      );

      // 添加支付宝
      await _accountService.addAccount(
        Account(
          name: '支付宝',
          type: '电子钱包',
          balance: 0.0,
          icon: 'mobile-screen',
          color: '0xFF1677FF',
        ),
      );

      // 添加工商银行
      await _accountService.addAccount(
        Account(
          name: '工商银行',
          type: '银行卡',
          balance: 0.0,
          icon: 'credit-card',
          color: '0xFFE53935',
        ),
      );

      // 添加基金钱包
      await _accountService.addAccount(
        Account(
          name: '基金钱包',
          type: '投资',
          balance: 0.0,
          icon: 'money-bill-trend-up',
          color: '0xFFFF9800',
        ),
      );
    }
  }

  // 获取所有账户
  Future<void> _fetchAccounts() async {
    _accounts = await _accountService.getAllAccounts();
    print("--- [AccountProvider._fetchAccounts] 完成 ---");
    print("获取到 ${_accounts.length} 个账户:");
    for (var acc in _accounts) {
      print("  ID: ${acc.id}, Name: ${acc.name}, Balance: ${acc.balance}");
    }
    notifyListeners();
  }

  // 获取总资产
  Future<void> _fetchTotalAssets() async {
    _totalAssets = await _accountService.getTotalAssets();
    print("--- [AccountProvider._fetchTotalAssets] 完成 ---");
    print("获取到总资产: $_totalAssets");
    notifyListeners();
  }

  // 同步账户数据（仅重新获取，不重新计算余额）
  Future<void> syncData() async {
    print("--- [AccountProvider.syncData] 开始 --- (isLoading=$_isLoading)");
    if (_isLoading) return;
    _setLoading(true);

    try {
      await _fetchAccounts();
      await _fetchTotalAssets();
      _setError(null);
      print("--- [AccountProvider.syncData] 成功完成 ---");
    } catch (e) {
      _setError('同步账户数据失败：$e');
      print("[ERROR] AccountProvider.syncData 失败: $e");
    } finally {
      _setLoading(false);
      print("--- [AccountProvider.syncData] 结束 --- (isLoading=$_isLoading)");
    }
  }

  // 添加账户
  Future<bool> addAccount(Account account) async {
    _setLoading(true);

    try {
      await _accountService.addAccount(account);
      await _fetchAccounts();
      await _fetchTotalAssets();
      _setError(null);
      return true;
    } catch (e) {
      _setError('添加账户失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新账户
  Future<bool> updateAccount(Account account) async {
    _setLoading(true);

    try {
      await _accountService.updateAccount(account);
      await _fetchAccounts();
      await _fetchTotalAssets();
      _setError(null);
      return true;
    } catch (e) {
      _setError('更新账户失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除账户
  Future<bool> deleteAccount(int id, {bool deleteTransactions = true}) async {
    _setLoading(true);

    try {
      await _accountService.deleteAccount(
        id,
        deleteTransactions: deleteTransactions,
      );
      await _fetchAccounts();
      await _fetchTotalAssets();
      _setError(null);
      return true;
    } catch (e) {
      _setError('删除账户失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
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
