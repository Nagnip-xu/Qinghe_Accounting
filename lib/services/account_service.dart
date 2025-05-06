import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import 'database_service.dart';

class AccountService {
  final DatabaseService _databaseService = DatabaseService();

  // 获取所有账户
  Future<List<Account>> getAllAccounts() async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  // 获取单个账户
  Future<Account?> getAccount(int id) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  // 添加账户
  Future<int> addAccount(Account account) async {
    final Database db = await _databaseService.database;
    return await db.insert('accounts', account.toMap());
  }

  // 更新账户
  Future<int> updateAccount(Account account) async {
    final Database db = await _databaseService.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // 删除账户
  Future<int> deleteAccount(int id, {bool deleteTransactions = true}) async {
    final Database db = await _databaseService.database;

    // 开始事务确保数据一致性
    return await db.transaction((txn) async {
      // 如果选择删除交易记录，则删除与该账户相关的所有交易
      if (deleteTransactions) {
        await txn.delete(
          'transactions',
          where: 'accountId = ? OR toAccountId = ?',
          whereArgs: [id, id],
        );
      }

      // 然后删除账户本身
      return await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
    });
  }

  // 获取总资产
  Future<double> getTotalAssets() async {
    // 确保从数据库获取最新的账户数据
    final Database db = await _databaseService.database;

    // 直接计算所有账户余额的总和（不管是否为负债账户）
    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts',
    );

    if (result.isNotEmpty) {
      // 获取总余额，可能为null
      final total = result.first['total'];

      // 如果为null则返回0，否则转换为double
      final double totalAssets =
          total == null
              ? 0.0
              : (total is double ? total : double.tryParse('$total') ?? 0.0);
      print('计算总资产: 总计=$totalAssets');
      return totalAssets;
    }

    return 0.0;
  }

  // 重新计算并同步所有账户的余额
  Future<bool> syncAccountBalances() async {
    try {
      final Database db = await _databaseService.database;

      // 开始事务
      await db.transaction((txn) async {
        // 1. 先获取所有账户
        final List<Map<String, dynamic>> accounts = await txn.query('accounts');

        print('开始同步账户余额，找到${accounts.length}个账户');

        // 2. 对每个账户重新计算余额
        for (var account in accounts) {
          final int accountId = account['id'];
          print('开始处理账户ID: $accountId');

          // --- 修改：统一查询并处理所有交易类型 ---
          double calculatedBalance = 0.0;

          // 获取与该账户相关的所有交易记录
          final List<Map<String, dynamic>> allTransactions = await txn.query(
            'transactions',
            // 查询条件：accountId 匹配 或 toAccountId 匹配 (用于转账和转入)
            where: 'accountId = ? OR toAccountId = ?',
            whereArgs: [accountId, accountId],
          );

          print('账户#$accountId 找到 ${allTransactions.length} 条相关交易');

          // 遍历所有交易，根据类型计算余额
          for (var tx in allTransactions) {
            final String type = tx['type'];
            final double amount = tx['amount']; // amount 现在可能是负数（对于调整）
            final int? txAccountId = tx['accountId'];
            final int? txToAccountId = tx['toAccountId'];

            if (type == '收入' && txAccountId == accountId) {
              calculatedBalance += amount;
              print('  处理 收入: +$amount -> $calculatedBalance');
            } else if (type == '支出' && txAccountId == accountId) {
              calculatedBalance -= amount;
              print('  处理 支出: -$amount -> $calculatedBalance');
            } else if (type == '转账') {
              if (txAccountId == accountId) {
                // 当前账户是转出方
                calculatedBalance -= amount;
                print('  处理 转出: -$amount -> $calculatedBalance');
              } else if (txToAccountId == accountId) {
                // 当前账户是转入方
                calculatedBalance += amount;
                print('  处理 转入: +$amount -> $calculatedBalance');
              }
            } else if (type == '调整' && txAccountId == accountId) {
              // amount 已经是带符号的调整金额
              calculatedBalance += amount;
              print('  处理 调整: $amount -> $calculatedBalance');
            }
          }
          // --- 修改结束 ---

          double finalBalance = calculatedBalance;

          // 如果是负债账户，余额符号反转（计算出的正数变负债，负数变资产? 逻辑确认）
          // 负债账户逻辑：计算出的余额代表欠款额。如果 calculatedBalance 为正，说明净支出>净收入，即欠款，余额应为负。
          // 如果 calculatedBalance 为负，说明净收入>净支出，即有盈余/还款，余额应为正。
          if (account['isDebt'] == 1) {
            // 对于负债账户，保持余额原始计算，不做反转，允许余额为负数
            finalBalance = calculatedBalance;
            print('  账户#$accountId 是负债账户，最终余额为: $finalBalance');
          }

          print(
            '账户#$accountId 最终计算余额: $finalBalance (基于 ${allTransactions.length} 条交易)',
          );

          // 更新账户余额
          await txn.update(
            'accounts',
            {'balance': finalBalance},
            where: 'id = ?',
            whereArgs: [accountId],
          );

          print('账户#$accountId 余额已更新为: $finalBalance');
        }
      });

      // 同步完成后，再次获取总资产以确认
      final totalAssets = await getTotalAssets();
      print('所有账户余额同步完成，总资产为: $totalAssets');

      return true;
    } catch (e) {
      print('同步账户余额失败: $e');
      return false;
    }
  }

  // 更新账户余额
  Future<int> updateAccountBalance(int accountId, double newBalance) async {
    final Database db = await _databaseService.database;
    return await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
}
