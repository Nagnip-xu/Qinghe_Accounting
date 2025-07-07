import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';
import 'database_service.dart';
import 'account_service.dart';
import '../models/account.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class TransactionService {
  final DatabaseService _databaseService = DatabaseService();
  final AccountService _accountService = AccountService();
  final dbHelper = DatabaseHelper.instance;

  // 获取所有交易记录
  Future<List<Transaction>> getAllTransactions() async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // 获取最近的交易记录
  Future<List<Transaction>> getRecentTransactions({
    int limit = 10,
    int offset = 0,
  }) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // 获取单个交易记录
  Future<Transaction?> getTransaction(int id) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final transaction = Transaction.fromMap(maps.first);

      // 如果是转账交易，补充目标账户名称
      if (transaction.type == '转账' && transaction.toAccountId != null) {
        final toAccount = await _accountService.getAccount(
          transaction.toAccountId!,
        );
        if (toAccount != null) {
          // 使用copyWith方法创建带有目标账户名称的新实例
          return transaction.copyWith(toAccountName: toAccount.name);
        }
      }

      return transaction;
    }
    return null;
  }

  // 添加交易记录并更新账户余额
  Future<int> addTransaction(Transaction transaction) async {
    try {
      final Database db = await _databaseService.database;

      // --- 添加日志 --- //
      print("--- [TransactionService.addTransaction] 开始 ---");
      print(
        "传入交易类型: ${transaction.type}, 金额: ${transaction.amount}, 账户ID: ${transaction.accountId}, 目标账户ID: ${transaction.toAccountId}",
      );
      print("传入交易详情: ${transaction.toMap()}");
      // --- 添加日志结束 --- //

      // 预先获取所需的账户信息
      final Map<String, dynamic> accountsInfo = {};

      int accountId = 0;
      try {
        accountId =
            transaction.accountId is int
                ? transaction.accountId
                : int.tryParse(transaction.accountId.toString()) ?? 0;
      } catch (e) {
        print('[ERROR] 账户ID转换错误: $e');
        throw Exception('账户ID格式错误');
      }

      if (accountId <= 0) {
        print('[ERROR] 无效的账户ID: $accountId');
        throw Exception('无效的账户ID: $accountId');
      }

      final fromAccount = await _accountService.getAccount(accountId);
      if (fromAccount == null) {
        print('[ERROR] 找不到账户 ID $accountId');
        throw Exception('找不到账户');
      }
      accountsInfo['fromAccount'] = fromAccount;
      // --- 添加日志 --- //
      print(
        "源账户信息: ID=${fromAccount.id}, Name=${fromAccount.name}, Balance=${fromAccount.balance}",
      );
      // --- 添加日志结束 --- //

      int? toAccountId;
      if (transaction.type == '转账' && transaction.toAccountId != null) {
        try {
          toAccountId =
              transaction.toAccountId is int
                  ? transaction.toAccountId
                  : int.tryParse(transaction.toAccountId.toString()) ?? 0;
        } catch (e) {
          print('[ERROR] 目标账户ID转换错误: $e');
          throw Exception('目标账户ID格式错误');
        }

        if (toAccountId == null || toAccountId <= 0) {
          print('[ERROR] 无效的目标账户ID: $toAccountId');
          throw Exception('无效的目标账户ID: $toAccountId');
        }

        final toAccount = await _accountService.getAccount(toAccountId);
        if (toAccount == null) {
          print('[ERROR] 找不到目标账户 ID $toAccountId');
          throw Exception('找不到目标账户');
        }
        accountsInfo['toAccount'] = toAccount;
        // --- 添加日志 --- //
        print(
          "目标账户信息: ID=${toAccount.id}, Name=${toAccount.name}, Balance=${toAccount.balance}",
        );
        // --- 添加日志结束 --- //
      }

      // 开始事务
      print("--- [TransactionService.addTransaction] 进入事务 ---");
      return await db.transaction((txn) async {
        try {
          // 插入交易记录
          final map = transaction.toMap();
          map.remove('id'); // Ensure id is null for insert
          map.remove('toAccountName'); // Ensure toAccountName is not included

          // 检查必要字段是否存在
          if (!map.containsKey('type') ||
              !map.containsKey('amount') ||
              !map.containsKey('accountId') ||
              !map.containsKey('accountName')) {
            print('交易记录缺少必要字段: ${map.keys.toList()}');
            throw Exception('交易记录缺少必要字段');
          }

          // 确保金额大于0
          if (map['amount'] <= 0) {
            print('[ERROR-TXN] 交易金额必须大于0: ${map['amount']}');
            throw Exception('交易金额必须大于0');
          }

          // 确保所有字段类型正确
          if (map['categoryName'] is! String) {
            map['categoryName'] = '${map['categoryName']}';
          }

          if (map['categoryIcon'] is! String) {
            map['categoryIcon'] = '${map['categoryIcon']}';
          }

          // 检查字段是否为null或空
          map['categoryName'] = map['categoryName'] ?? '未分类';
          map['categoryIcon'] = map['categoryIcon'] ?? 'default';
          map['note'] = map['note'] ?? '';

          // --- 添加日志 --- //
          print("[TXN] 准备插入交易: $map");
          // --- 添加日志结束 --- //
          final int id = await txn.insert('transactions', {
            'type': map['type'],
            'amount': map['amount'],
            'categoryId': map['categoryId'],
            'categoryName': map['categoryName'],
            'categoryIcon': map['categoryIcon'],
            'categoryColor': map['categoryColor'],
            'accountId': map['accountId'],
            'accountName': map['accountName'],
            'date': map['date'],
            'note': map['note'],
            'toAccountId': map['toAccountId'],
          });
          // --- 添加日志 --- //
          print("[TXN] 交易记录已插入，ID: $id");
          // --- 添加日志结束 --- //

          // 根据交易类型更新账户余额
          if (transaction.type == '支出') {
            final account = accountsInfo['fromAccount'] as Account;
            final double amount = transaction.amount.abs();

            // 添加对非负债账户的余额检查
            if (!account.isDebt && amount > account.balance) {
              print("[TXN] 非负债账户余额不足: 当前余额=${account.balance}, 支出金额=$amount");
              throw Exception('账户余额不足，无法完成交易');
            }

            // 移除对非负债账户的余额检查，只保留余额更新逻辑
            final newBalance = account.balance - amount;
            // --- 添加日志 --- //
            print(
              "[TXN] 更新账户 (支出): ID=$accountId, 旧余额=${account.balance}, 新余额=$newBalance",
            );
            // --- 添加日志结束 --- //
            await txn.update(
              'accounts',
              {'balance': newBalance},
              where: 'id = ?',
              whereArgs: [accountId],
            );
          } else if (transaction.type == '收入') {
            final account = accountsInfo['fromAccount'] as Account;
            final double amount = transaction.amount.abs();
            final newBalance = account.balance + amount;
            // --- 添加日志 --- //
            print(
              "[TXN] 更新账户 (收入): ID=$accountId, 旧余额=${account.balance}, 新余额=$newBalance",
            );
            // --- 添加日志结束 --- //
            await txn.update(
              'accounts',
              {'balance': newBalance},
              where: 'id = ?',
              whereArgs: [accountId],
            );
          } else if (transaction.type == '转账' && toAccountId != null) {
            final fromAccount = accountsInfo['fromAccount'] as Account;
            final toAccount = accountsInfo['toAccount'] as Account;

            final double amount = transaction.amount.abs();

            // 添加对非负债账户的余额检查
            if (!fromAccount.isDebt && amount > fromAccount.balance) {
              print(
                "[TXN] 非负债账户余额不足: 当前余额=${fromAccount.balance}, 转账金额=$amount",
              );
              throw Exception('转出账户余额不足，无法完成转账交易');
            }

            final newFromBalance = fromAccount.balance - amount;
            final newToBalance = toAccount.balance + amount;

            // --- 添加日志 --- //
            print(
              "[TXN] 更新转出账户: ID=${fromAccount.id}, 旧余额=${fromAccount.balance}, 新余额=$newFromBalance",
            );
            // --- 添加日志结束 --- //
            await txn.update(
              'accounts',
              {'balance': newFromBalance},
              where: 'id = ?',
              whereArgs: [fromAccount.id],
            );
            // --- 添加日志 --- //
            print(
              "[TXN] 更新转入账户: ID=${toAccount.id}, 旧余额=${toAccount.balance}, 新余额=$newToBalance",
            );
            // --- 添加日志结束 --- //
            await txn.update(
              'accounts',
              {'balance': newToBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
          }
          print("--- [TransactionService.addTransaction] 事务成功提交 ---");
          return id;
        } catch (e) {
          print('[ERROR-TXN] 事务内部错误: $e');
          rethrow; // 将错误重新抛出，让外层捕获
        }
      }); // db.transaction 结束
    } catch (e) {
      print('[ERROR] TransactionService.addTransaction 外层错误: $e');
      rethrow; // 继续向上抛出，让 Provider 处理
    }
  }

  // 更新交易记录
  Future<void> updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    try {
      final Database db = await _databaseService.database;

      print("--- [TransactionService.updateTransaction] 开始 ---");
      print("旧交易: ${oldTransaction.toMap()}");
      print("新交易: ${newTransaction.toMap()}");

      // 预获取可能需要的账户信息
      final Map<int, Account> accountsCache = {};
      int oldAccountId =
          oldTransaction.accountId is int
              ? oldTransaction.accountId
              : int.parse(oldTransaction.accountId.toString());
      accountsCache[oldAccountId] =
          (await _accountService.getAccount(oldAccountId))!;

      // 定义两个变量用于可能的转账情况
      int? oldToAccountId;
      int? newToAccountId;

      if (oldTransaction.toAccountId != null) {
        oldToAccountId =
            oldTransaction.toAccountId is int
                ? oldTransaction.toAccountId
                : int.parse(oldTransaction.toAccountId.toString());
        // 确保转换后的ID不为null，并使用非空断言
        if (oldToAccountId != null) {
          accountsCache[oldToAccountId] =
              (await _accountService.getAccount(oldToAccountId))!;
        }
      }

      int newAccountId =
          newTransaction.accountId is int
              ? newTransaction.accountId
              : int.parse(newTransaction.accountId.toString());
      if (newAccountId != oldAccountId) {
        accountsCache[newAccountId] =
            (await _accountService.getAccount(newAccountId))!;
      }

      if (newTransaction.toAccountId != null) {
        newToAccountId =
            newTransaction.toAccountId is int
                ? newTransaction.toAccountId
                : int.parse(newTransaction.toAccountId.toString());
        // 确保转换后的ID不为null且与老的toAccountId不同，使用非空断言
        if (newToAccountId != null &&
            (oldToAccountId == null || newToAccountId != oldToAccountId)) {
          accountsCache[newToAccountId] =
              (await _accountService.getAccount(newToAccountId))!;
        }
      }

      // 开始事务
      print("--- [TransactionService.updateTransaction] 进入事务 ---");
      await db.transaction((txn) async {
        try {
          // --- 1. 回滚旧交易对账户余额的影响 --- //
          print("[TXN-UPDATE] 开始回滚旧交易影响...");
          if (oldTransaction.type == '支出') {
            final account = accountsCache[oldAccountId]!;
            final amount = oldTransaction.amount.abs();
            final originalBalance = account.balance + amount; // 回滚：加回支出金额
            print(
              "[TXN-UPDATE] 回滚支出: 账户ID=${account.id}, 回滚后余额=$originalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
            accountsCache[account.id!] = account.copyWith(
              balance: originalBalance,
            );
          } else if (oldTransaction.type == '收入') {
            final account = accountsCache[oldAccountId]!;
            final amount = oldTransaction.amount.abs();
            final originalBalance = account.balance - amount; // 回滚：减去收入金额
            print(
              "[TXN-UPDATE] 回滚收入: 账户ID=${account.id}, 回滚后余额=$originalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
            accountsCache[account.id!] = account.copyWith(
              balance: originalBalance,
            );
          } else if (oldTransaction.type == '转账' &&
              oldTransaction.toAccountId != null &&
              oldToAccountId != null) {
            final fromAccount = accountsCache[oldAccountId]!;
            // 确保当前缓存中存在目标账户
            if (!accountsCache.containsKey(oldToAccountId)) {
              print('[ERROR-TXN-UPDATE] 缓存中缺少目标账户, ID: $oldToAccountId');
              throw Exception('缓存中缺少目标账户');
            }
            final toAccount = accountsCache[oldToAccountId]!;
            final amount = oldTransaction.amount.abs();

            // 回滚转出账户：加回转出金额
            final fromOriginalBalance = fromAccount.balance + amount;
            print(
              "[TXN-UPDATE] 回滚转账(转出): 账户ID=${fromAccount.id}, 回滚后余额=$fromOriginalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': fromOriginalBalance},
              where: 'id = ?',
              whereArgs: [fromAccount.id],
            );
            accountsCache[fromAccount.id!] = fromAccount.copyWith(
              balance: fromOriginalBalance,
            );

            // 回滚转入账户：减去转入金额
            final toOriginalBalance = toAccount.balance - amount;
            print(
              "[TXN-UPDATE] 回滚转账(转入): 账户ID=${toAccount.id}, 回滚后余额=$toOriginalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': toOriginalBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
            accountsCache[toAccount.id!] = toAccount.copyWith(
              balance: toOriginalBalance,
            );
          }

          // --- 2. 应用新交易的账户余额影响 --- //
          print("[TXN-UPDATE] 开始应用新交易影响...");
          if (newTransaction.type == '支出') {
            final account = accountsCache[newAccountId]!;
            final amount = newTransaction.amount.abs();

            // 添加对非负债账户的余额检查
            if (!account.isDebt && amount > account.balance) {
              print(
                "[TXN-UPDATE] 非负债账户余额不足: 当前余额=${account.balance}, 支出金额=$amount",
              );
              throw Exception('账户余额不足，无法完成交易');
            }

            final newBalance = account.balance - amount; // 应用：减去支出金额
            print("[TXN-UPDATE] 应用支出: 账户ID=${account.id}, 新余额=$newBalance");
            await txn.update(
              'accounts',
              {'balance': newBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (newTransaction.type == '收入') {
            final account = accountsCache[newAccountId]!;
            final amount = newTransaction.amount.abs();
            final newBalance = account.balance + amount; // 应用：加上收入金额
            print("[TXN-UPDATE] 应用收入: 账户ID=${account.id}, 新余额=$newBalance");
            await txn.update(
              'accounts',
              {'balance': newBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (newTransaction.type == '转账' &&
              newTransaction.toAccountId != null &&
              newToAccountId != null) {
            final fromAccount = accountsCache[newAccountId]!;
            // 确保当前缓存中存在目标账户
            if (!accountsCache.containsKey(newToAccountId)) {
              print('[ERROR-TXN-UPDATE] 缓存中缺少目标账户, ID: $newToAccountId');
              throw Exception('缓存中缺少目标账户');
            }
            final toAccount = accountsCache[newToAccountId]!;
            final amount = newTransaction.amount.abs();

            // 添加对非负债账户的余额检查
            if (!fromAccount.isDebt && amount > fromAccount.balance) {
              print(
                "[TXN-UPDATE] 非负债账户余额不足: 当前余额=${fromAccount.balance}, 转账金额=$amount",
              );
              throw Exception('转出账户余额不足，无法完成转账交易');
            }

            // 应用转出账户：减去转出金额
            final fromNewBalance = fromAccount.balance - amount;
            print(
              "[TXN-UPDATE] 应用转账(转出): 账户ID=${fromAccount.id}, 新余额=$fromNewBalance",
            );
            await txn.update(
              'accounts',
              {'balance': fromNewBalance},
              where: 'id = ?',
              whereArgs: [fromAccount.id],
            );

            // 应用转入账户：加上转入金额
            final toNewBalance = toAccount.balance + amount;
            print(
              "[TXN-UPDATE] 应用转账(转入): 账户ID=${toAccount.id}, 新余额=$toNewBalance",
            );
            await txn.update(
              'accounts',
              {'balance': toNewBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
          }

          // --- 3. 更新交易记录 --- //
          await txn.update(
            'transactions',
            newTransaction.toMap(),
            where: 'id = ?',
            whereArgs: [newTransaction.id],
          );

          print("--- [TransactionService.updateTransaction] 事务完成 ---");
        } catch (e) {
          print("--- [TransactionService.updateTransaction] 事务失败: $e ---");
          rethrow;
        }
      });
    } catch (e) {
      print('更新交易记录失败: $e');
      rethrow;
    }
  }

  // 删除交易记录并调整账户余额
  Future<bool> deleteTransaction(Transaction transaction) async {
    try {
      final Database db = await _databaseService.database;

      if (transaction.id == null) {
        throw Exception('删除交易需要提供有效的交易ID');
      }

      // 获取交易所涉及的账户
      final int accountId =
          transaction.accountId is int
              ? transaction.accountId
              : int.parse(transaction.accountId.toString());
      final Account? account = await _accountService.getAccount(accountId);

      if (account == null) {
        throw Exception('找不到关联的账户，无法处理账户余额调整');
      }

      Account? toAccount;
      if (transaction.type == '转账' && transaction.toAccountId != null) {
        final int toAccountId =
            transaction.toAccountId is int
                ? transaction.toAccountId
                : int.parse(transaction.toAccountId.toString());
        toAccount = await _accountService.getAccount(toAccountId);

        if (toAccount == null) {
          throw Exception('找不到转账目标账户，无法完成删除操作');
        }
      }

      // 开始事务
      print("--- [TransactionService.deleteTransaction] 开始事务 ---");
      await db.transaction((txn) async {
        try {
          // 根据交易类型更新账户余额
          if (transaction.type == '支出') {
            // 删除支出：增加账户余额
            final double amount = transaction.amount.abs();
            final double newBalance = account.balance + amount;

            print("[TXN-DELETE] 回滚支出: 账户ID=${account.id}, 新余额=$newBalance");
            await txn.update(
              'accounts',
              {'balance': newBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (transaction.type == '收入') {
            // 删除收入：减少账户余额
            final double amount = transaction.amount.abs();
            final double newBalance = account.balance - amount;

            print("[TXN-DELETE] 回滚收入: 账户ID=${account.id}, 新余额=$newBalance");
            await txn.update(
              'accounts',
              {'balance': newBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (transaction.type == '转账' && toAccount != null) {
            // 删除转账：恢复转出和转入账户余额
            final double amount = transaction.amount.abs();

            // 恢复转出账户余额
            final double fromNewBalance = account.balance + amount;
            print(
              "[TXN-DELETE] 回滚转账(转出): 账户ID=${account.id}, 新余额=$fromNewBalance",
            );
            await txn.update(
              'accounts',
              {'balance': fromNewBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );

            // 恢复转入账户余额
            final double toNewBalance = toAccount.balance - amount;
            print(
              "[TXN-DELETE] 回滚转账(转入): 账户ID=${toAccount.id}, 新余额=$toNewBalance",
            );
            await txn.update(
              'accounts',
              {'balance': toNewBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
          }

          // 删除交易记录
          final result = await txn.delete(
            'transactions',
            where: 'id = ?',
            whereArgs: [transaction.id],
          );

          print("[TXN-DELETE] 删除交易记录，影响行数: $result");
          print("--- [TransactionService.deleteTransaction] 事务完成 ---");
        } catch (e) {
          print("--- [TransactionService.deleteTransaction] 事务失败: $e ---");
          rethrow;
        }
      });
    } catch (e) {
      print('删除交易记录失败: $e');
      rethrow;
    }
    return true; // 如果没有抛出异常，则认为成功
  }

  // 获取特定账户的交易记录
  Future<List<Transaction>> getTransactionsForAccount(
    int accountId, {
    DateTime? startDate,
  }) async {
    final Database db = await _databaseService.database;

    String whereClause =
        'accountId = ? OR toAccountId = ?'; // 查询涉及该账户的所有交易（转入或转出）
    List<dynamic> whereArgs = [accountId, accountId];

    // 如果提供了开始日期，添加日期过滤条件
    if (startDate != null) {
      final String formattedDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(startDate);
      whereClause += ' AND date >= ?';
      whereArgs.add(formattedDate);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    // 补充目标账户名称
    final List<Transaction> transactions = [];
    for (final map in maps) {
      var transaction = Transaction.fromMap(map);
      if (transaction.type == '转账') {
        int? relatedAccountId;
        if (transaction.accountId == accountId) {
          // 转出
          relatedAccountId = transaction.toAccountId;
        } else {
          // 转入
          relatedAccountId = transaction.accountId;
        }
        if (relatedAccountId != null) {
          final relatedAccount = await _accountService.getAccount(
            relatedAccountId,
          );
          if (relatedAccount != null) {
            if (transaction.accountId == accountId) {
              // 转出
              transaction = transaction.copyWith(
                toAccountName: relatedAccount.name,
              );
            } else {
              // 转入
              // fromAccountName 实际上就是 transaction.accountName，不需要额外设置
            }
          }
        }
      }
      transactions.add(transaction);
    }

    return transactions;
  }

  // 获取特定月份的收入总额 - 完全重写的方法
  Future<double> getMonthlyIncome(int year, int month) async {
    print("[CRITICAL] 重新实现的getMonthlyIncome方法被调用: $year-$month");

    try {
      final db = await _databaseService.database;
      final yearStr = year.toString();
      final monthStr = month.toString().padLeft(2, '0');
      final monthFormat = "$yearStr-$monthStr";

      // 直接使用SQL查询来获取月份收入总额
      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as totalIncome
        FROM transactions
        WHERE type = '收入' AND substr(date, 1, 7) = ?
      ''',
        [monthFormat],
      );

      final income = result.first['totalIncome'];
      print("[CRITICAL] $year年$month月收入统计: SQL查询结果 $income");

      // 处理不同类型的返回值，确保返回double
      if (income == null) return 0.0;
      if (income is int) return income.toDouble();
      if (income is double) return income;
      return double.tryParse(income.toString()) ?? 0.0;
    } catch (e) {
      print("[CRITICAL ERROR] 获取月度收入时发生错误: $e");
      return 0.0;
    }
  }

  // 获取特定月份的支出总额 - 完全重写的方法
  Future<double> getMonthlyExpense(int year, int month) async {
    print("[CRITICAL] 重新实现的getMonthlyExpense方法被调用: $year-$month");

    try {
      final db = await _databaseService.database;
      final yearStr = year.toString();
      final monthStr = month.toString().padLeft(2, '0');
      final monthFormat = "$yearStr-$monthStr";

      // 直接使用SQL查询来获取月份支出总额
      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as totalExpense
        FROM transactions
        WHERE type = '支出' AND substr(date, 1, 7) = ?
      ''',
        [monthFormat],
      );

      final expense = result.first['totalExpense'];
      print("[CRITICAL] $year年$month月支出统计: SQL查询结果 $expense");

      // 处理不同类型的返回值，确保返回double
      if (expense == null) return 0.0;
      if (expense is int) return expense.toDouble();
      if (expense is double) return expense;
      return double.tryParse(expense.toString()) ?? 0.0;
    } catch (e) {
      print("[CRITICAL ERROR] 获取月度支出时发生错误: $e");
      return 0.0;
    }
  }

  // 获取特定分类的月度支出
  Future<double> getCategoryMonthlyExpense(
    int year,
    int month,
    String categoryId,
  ) async {
    final db = await dbHelper.database;

    // 构建年月字符串用于日志
    final String yearStr = year.toString();
    final String monthStr = month.toString().padLeft(2, '0');

    print(
      "[INFO] getCategoryMonthlyExpense: 查询月份 $yearStr-$monthStr, 分类 $categoryId",
    );

    // 使用substr函数提取日期的年月部分进行匹配
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as categoryExpense
      FROM transactions
      WHERE type = '支出' 
      AND categoryId = ?
      AND substr(date, 1, 7) = ?
    ''',
      [categoryId, "$yearStr-$monthStr"],
    );

    if (result.isNotEmpty) {
      final expense = result.first['categoryExpense'];
      print("[SQL_RESULT] 分类月度支出查询结果: $expense");
      if (expense is int) {
        return expense.toDouble();
      }
      return expense as double? ?? 0.0;
    }

    return 0.0;
  }

  // 搜索交易记录
  Future<List<Transaction>> searchTransactions(String query) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'categoryName LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // 根据日期范围获取交易记录
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // 根据类别获取交易记录
  Future<List<Transaction>> getTransactionsByCategory(int categoryId) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // --- 新增：获取按分类的月度支出 --- //
  Future<Map<String, double>> getMonthlyExpenseByCategory(
    String yearMonth,
  ) async {
    final Database db = await _databaseService.database;

    // 规范化月份格式：支持yyyy-MM和yyyyMM两种格式
    String yearMonthStr;

    if (yearMonth.contains('-')) {
      // 格式已经是yyyy-MM，直接使用
      yearMonthStr = yearMonth;
      print("[INFO] getMonthlyExpenseByCategory: 使用已格式化的月份 $yearMonth");
    } else if (yearMonth.length == 6) {
      // 格式为yyyyMM，转换为yyyy-MM
      final year = yearMonth.substring(0, 4);
      final month = yearMonth.substring(4, 6);
      yearMonthStr = "$year-$month";
      print(
        "[INFO] getMonthlyExpenseByCategory: 转换月份格式 $yearMonth → $yearMonthStr",
      );
    } else {
      print("[ERROR] getMonthlyExpenseByCategory: 无效的月份格式 '$yearMonth'");
      return {};
    }

    // 查询指定月份、类型为支出的交易，按类别分组并计算总额
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT categoryName, SUM(amount) as total
      FROM transactions
      WHERE type = ? AND substr(date, 1, 7) = ?
      GROUP BY categoryName
    ''',
      ['支出', yearMonthStr],
    );

    final Map<String, double> categoryExpenses = {};
    for (var row in result) {
      final categoryName = row['categoryName'] as String?;
      final total = row['total'] as num?;
      if (categoryName != null && total != null) {
        // 数据库中存储的支出金额为正数，直接使用
        categoryExpenses[categoryName] = total.toDouble();
      }
    }
    print("[INFO] getMonthlyExpenseByCategory: 查询结果 $categoryExpenses");
    return categoryExpenses;
  }

  // --- 新增结束 --- //

  // 获取指定账户的交易记录
  Future<List<Transaction>> getTransactionsByAccount(int accountId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'accountId = ? OR toAccountId = ?',
        whereArgs: [accountId, accountId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
    } catch (e) {
      print('获取账户交易记录失败: $e');
      return [];
    }
  }

  // --- 调试：打印某个月份的所有交易记录 --- //
  Future<void> debugPrintMonthTransactions(int year, int month) async {
    final db = await dbHelper.database;
    final String yearStr = year.toString();
    final String monthStr = month.toString().padLeft(2, '0');

    print("====== [DEBUG] $yearStr-$monthStr 月份交易记录 ======");

    // 查询指定月份的所有交易
    final result = await db.rawQuery(
      '''
      SELECT id, type, amount, date, categoryName, accountName
      FROM transactions
      WHERE substr(date, 1, 7) = ?
      ORDER BY date DESC
    ''',
      ["$yearStr-$monthStr"],
    );

    if (result.isEmpty) {
      print("[DEBUG] 该月份无交易记录");
    } else {
      print("[DEBUG] 找到 ${result.length} 条交易记录:");
      for (var row in result) {
        print(
          "[DEBUG] ID: ${row['id']}, 类型: ${row['type']}, 金额: ${row['amount']}, 日期: ${row['date']}, 分类: ${row['categoryName']}, 账户: ${row['accountName']}",
        );
      }
    }

    // 查询当月收入总额
    final incomeResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as totalIncome
      FROM transactions
      WHERE type = '收入' AND substr(date, 1, 7) = ?
    ''',
      ["$yearStr-$monthStr"],
    );

    final income = incomeResult.first['totalIncome'];
    print("[DEBUG] 当月收入总额: $income");

    // 查询当月支出总额
    final expenseResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as totalExpense
      FROM transactions
      WHERE type = '支出' AND substr(date, 1, 7) = ?
    ''',
      ["$yearStr-$monthStr"],
    );

    final expense = expenseResult.first['totalExpense'];
    print("[DEBUG] 当月支出总额: $expense");

    // 查询原始数据中的日期格式
    final dateFormatResult = await db.rawQuery('''
      SELECT id, date FROM transactions LIMIT 5
    ''');

    if (dateFormatResult.isNotEmpty) {
      print("[DEBUG] 数据库中的日期格式样例:");
      for (var row in dateFormatResult) {
        print("[DEBUG] ID: ${row['id']}, 日期原始格式: ${row['date']}");
      }
    }

    print("====== [DEBUG] 调试信息结束 ======");
  }
}
