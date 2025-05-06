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

      if (transaction.type == '转账' && transaction.toAccountId != null) {
        int toAccountId = 0;
        try {
          toAccountId =
              transaction.toAccountId is int
                  ? transaction.toAccountId
                  : int.tryParse(transaction.toAccountId.toString()) ?? 0;
        } catch (e) {
          print('[ERROR] 目标账户ID转换错误: $e');
          throw Exception('目标账户ID格式错误');
        }

        if (toAccountId <= 0) {
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
          } else if (transaction.type == '转账' &&
              transaction.toAccountId != null) {
            final fromAccount = accountsInfo['fromAccount'] as Account;
            final toAccount = accountsInfo['toAccount'] as Account;

            int toAccountId =
                transaction.toAccountId is int
                    ? transaction.toAccountId
                    : int.tryParse(transaction.toAccountId.toString()) ?? 0;

            final double amount = transaction.amount.abs();

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
              whereArgs: [toAccountId],
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

  // 更新交易记录并调整账户余额
  Future<bool> updateTransaction(Transaction newTransaction) async {
    try {
      final Database db = await _databaseService.database;
      if (newTransaction.id == null) {
        throw Exception('更新交易需要提供有效的交易 ID');
      }

      // 获取原始交易记录
      final oldTransaction = await getTransaction(newTransaction.id!);
      if (oldTransaction == null) {
        throw Exception('找不到要更新的原始交易记录');
      }

      print("--- [TransactionService.updateTransaction] 开始 ---");
      print("旧交易: ${oldTransaction.toMap()}");
      print("新交易: ${newTransaction.toMap()}");

      // 预获取可能需要的账户信息
      final Map<int, Account> accountsCache = {};
      accountsCache[oldTransaction.accountId] =
          (await _accountService.getAccount(oldTransaction.accountId))!;
      if (oldTransaction.toAccountId != null) {
        accountsCache[oldTransaction.toAccountId] =
            (await _accountService.getAccount(oldTransaction.toAccountId))!;
      }
      if (newTransaction.accountId != oldTransaction.accountId) {
        accountsCache[newTransaction.accountId] =
            (await _accountService.getAccount(newTransaction.accountId))!;
      }
      if (newTransaction.toAccountId != null &&
          newTransaction.toAccountId != oldTransaction.toAccountId) {
        accountsCache[newTransaction.toAccountId] =
            (await _accountService.getAccount(newTransaction.toAccountId))!;
      }

      print("账户缓存: ${accountsCache.map((k, v) => MapEntry(k, v.name))}");

      // 开始事务
      print("--- [TransactionService.updateTransaction] 进入事务 ---");
      await db.transaction((txn) async {
        try {
          // --- 1. 回滚旧交易对账户余额的影响 --- //
          print("[TXN-UPDATE] 开始回滚旧交易影响...");
          if (oldTransaction.type == '支出') {
            final account = accountsCache[oldTransaction.accountId]!;
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
            ); // 更新缓存
          } else if (oldTransaction.type == '收入') {
            final account = accountsCache[oldTransaction.accountId]!;
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
            ); // 更新缓存
          } else if (oldTransaction.type == '转账' &&
              oldTransaction.toAccountId != null) {
            final fromAccount = accountsCache[oldTransaction.accountId]!;
            final toAccount = accountsCache[oldTransaction.toAccountId]!;
            final amount = oldTransaction.amount.abs();
            final originalFromBalance =
                fromAccount.balance + amount; // 回滚：转出账户加回金额
            final originalToBalance = toAccount.balance - amount; // 回滚：转入账户减去金额
            print(
              "[TXN-UPDATE] 回滚转账 (源): 账户ID=${fromAccount.id}, 回滚后余额=$originalFromBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalFromBalance},
              where: 'id = ?',
              whereArgs: [fromAccount.id],
            );
            print(
              "[TXN-UPDATE] 回滚转账 (目标): 账户ID=${toAccount.id}, 回滚后余额=$originalToBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalToBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
            accountsCache[fromAccount.id!] = fromAccount.copyWith(
              balance: originalFromBalance,
            ); // 更新缓存
            accountsCache[toAccount.id!] = toAccount.copyWith(
              balance: originalToBalance,
            ); // 更新缓存
          }
          print("[TXN-UPDATE] 旧交易影响回滚完成");

          // --- 2. 更新交易记录本身 --- //
          final map = newTransaction.toMap();
          print("[TXN-UPDATE] 准备更新交易记录: $map");
          map.remove('toAccountName'); // 数据库无此列
          await txn.update(
            'transactions',
            map,
            where: 'id = ?',
            whereArgs: [newTransaction.id],
          );
          print("[TXN-UPDATE] 交易记录更新完成");

          // --- 3. 应用新交易对账户余额的影响 --- //
          print("[TXN-UPDATE] 开始应用新交易影响...");
          if (newTransaction.type == '支出') {
            final account = accountsCache[newTransaction.accountId]!;
            final amount = newTransaction.amount.abs();
            // 移除对非负债账户的余额检查，只保留余额更新逻辑
            final finalBalance = account.balance - amount; // 应用新支出
            print(
              "[TXN-UPDATE] 应用新支出: 账户ID=${account.id}, 更新后余额=$finalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': finalBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (newTransaction.type == '收入') {
            final account = accountsCache[newTransaction.accountId]!;
            final amount = newTransaction.amount.abs();
            final finalBalance = account.balance + amount; // 应用新收入
            print(
              "[TXN-UPDATE] 应用新收入: 账户ID=${account.id}, 更新后余额=$finalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': finalBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (newTransaction.type == '转账' &&
              newTransaction.toAccountId != null) {
            final fromAccount = accountsCache[newTransaction.accountId]!;
            final toAccount = accountsCache[newTransaction.toAccountId]!;
            final amount = newTransaction.amount.abs();

            final finalFromBalance = fromAccount.balance - amount; // 应用新转出
            final finalToBalance = toAccount.balance + amount; // 应用新转入
            print(
              "[TXN-UPDATE] 应用新转账 (源): 账户ID=${fromAccount.id}, 更新后余额=$finalFromBalance",
            );
            await txn.update(
              'accounts',
              {'balance': finalFromBalance},
              where: 'id = ?',
              whereArgs: [fromAccount.id],
            );
            print(
              "[TXN-UPDATE] 应用新转账 (目标): 账户ID=${toAccount.id}, 更新后余额=$finalToBalance",
            );
            await txn.update(
              'accounts',
              {'balance': finalToBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
          }
          print("--- [TransactionService.updateTransaction] 事务成功提交 ---");
        } catch (e) {
          print('[ERROR-TXN-UPDATE] 更新事务内部错误: $e');
          rethrow;
        }
      });
    } catch (e) {
      print('[ERROR] TransactionService.updateTransaction 外层错误: $e');
      rethrow;
    }
    return true; // 如果没有抛出异常，则认为成功
  }

  // 删除交易记录并调整账户余额
  Future<bool> deleteTransaction(int id) async {
    try {
      final Database db = await _databaseService.database;

      // 获取要删除的交易记录
      final transactionToDelete = await getTransaction(id);
      if (transactionToDelete == null) {
        throw Exception('找不到要删除的交易记录');
      }

      print("--- [TransactionService.deleteTransaction] 开始 ---");
      print("准备删除交易: ${transactionToDelete.toMap()}");

      // 预获取需要的账户信息
      final Map<int, Account> accountsCache = {};
      accountsCache[transactionToDelete.accountId] =
          (await _accountService.getAccount(transactionToDelete.accountId))!;
      if (transactionToDelete.toAccountId != null) {
        accountsCache[transactionToDelete.toAccountId] =
            (await _accountService.getAccount(
              transactionToDelete.toAccountId,
            ))!;
      }
      print("账户缓存: ${accountsCache.map((k, v) => MapEntry(k, v.name))}");

      // 开始事务
      print("--- [TransactionService.deleteTransaction] 进入事务 ---");
      await db.transaction((txn) async {
        try {
          // --- 1. 回滚交易对账户余额的影响 --- //
          print("[TXN-DELETE] 开始回滚交易影响...");
          if (transactionToDelete.type == '支出') {
            final account = accountsCache[transactionToDelete.accountId]!;
            final amount = transactionToDelete.amount.abs();
            final originalBalance = account.balance + amount; // 回滚：加回支出
            print(
              "[TXN-DELETE] 回滚支出: 账户ID=${account.id}, 回滚后余额=$originalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (transactionToDelete.type == '收入') {
            final account = accountsCache[transactionToDelete.accountId]!;
            final amount = transactionToDelete.amount.abs();
            final originalBalance = account.balance - amount; // 回滚：减去收入
            print(
              "[TXN-DELETE] 回滚收入: 账户ID=${account.id}, 回滚后余额=$originalBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalBalance},
              where: 'id = ?',
              whereArgs: [account.id],
            );
          } else if (transactionToDelete.type == '转账' &&
              transactionToDelete.toAccountId != null) {
            final fromAccount = accountsCache[transactionToDelete.accountId]!;
            final toAccount = accountsCache[transactionToDelete.toAccountId]!;
            final amount = transactionToDelete.amount.abs();
            final originalFromBalance =
                fromAccount.balance + amount; // 回滚：源账户加回
            final originalToBalance = toAccount.balance - amount; // 回滚：目标账户减去
            print(
              "[TXN-DELETE] 回滚转账 (源): 账户ID=${fromAccount.id}, 回滚后余额=$originalFromBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalFromBalance},
              where: 'id = ?',
              whereArgs: [fromAccount.id],
            );
            print(
              "[TXN-DELETE] 回滚转账 (目标): 账户ID=${toAccount.id}, 回滚后余额=$originalToBalance",
            );
            await txn.update(
              'accounts',
              {'balance': originalToBalance},
              where: 'id = ?',
              whereArgs: [toAccount.id],
            );
          }
          print("[TXN-DELETE] 交易影响回滚完成");

          // --- 2. 删除交易记录 --- //
          print("[TXN-DELETE] 准备删除交易记录 ID: $id");
          await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
          print("[TXN-DELETE] 交易记录删除完成");
          print("--- [TransactionService.deleteTransaction] 事务成功提交 ---");
        } catch (e) {
          print('[ERROR-TXN-DELETE] 删除事务内部错误: $e');
          rethrow;
        }
      });
    } catch (e) {
      print('[ERROR] TransactionService.deleteTransaction 外层错误: $e');
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

  // 获取特定月份的收入总额
  Future<double> getMonthlyIncome(int year, int month) async {
    final db = await dbHelper.database;

    // 计算月份的起始日期和结束日期
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // 当月最后一天

    final startDateStr = startDate.toString().substring(0, 10);
    final endDateStr = endDate.toString().substring(0, 10);

    // 查询收入总额
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as totalIncome
      FROM transactions
      WHERE type = '收入' 
      AND date BETWEEN '$startDateStr' AND '$endDateStr'
    ''');

    if (result.isNotEmpty) {
      return result.first['totalIncome'] as double? ?? 0.0;
    }

    return 0.0;
  }

  // 获取特定月份的支出总额
  Future<double> getMonthlyExpense(int year, int month) async {
    final db = await dbHelper.database;

    // 计算月份的起始日期和结束日期
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // 当月最后一天

    final startDateStr = startDate.toString().substring(0, 10);
    final endDateStr = endDate.toString().substring(0, 10);

    // 查询支出总额
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as totalExpense
      FROM transactions
      WHERE type = '支出' 
      AND date BETWEEN '$startDateStr' AND '$endDateStr'
    ''');

    if (result.isNotEmpty) {
      return result.first['totalExpense'] as double? ?? 0.0;
    }

    return 0.0;
  }

  // 获取特定分类的月度支出
  Future<double> getCategoryMonthlyExpense(
    int year,
    int month,
    String categoryId,
  ) async {
    final db = await dbHelper.database;

    // 计算月份的起始日期和结束日期
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // 当月最后一天

    final startDateStr = startDate.toString().substring(0, 10);
    final endDateStr = endDate.toString().substring(0, 10);

    // 查询特定分类的支出总额
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as categoryExpense
      FROM transactions
      WHERE type = '支出' 
      AND categoryId = ?
      AND date BETWEEN '$startDateStr' AND '$endDateStr'
    ''',
      [categoryId],
    );

    if (result.isNotEmpty) {
      return result.first['categoryExpense'] as double? ?? 0.0;
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

    // SQLite 不直接支持 strftime 在 GROUP BY 或 WHERE 子句中，但我们可以使用 LIKE
    // 确保 yearMonth 格式为 'yyyyMM'
    if (yearMonth.length != 6) {
      print("[ERROR] getMonthlyExpenseByCategory: 无效的月份格式 '$yearMonth'");
      return {};
    }
    final String year = yearMonth.substring(0, 4);
    final String month = yearMonth.substring(4, 6);
    // 构建日期匹配模式，例如 '2023-10-%'
    final String datePattern = '$year-$month-%';

    print(
      "[INFO] getMonthlyExpenseByCategory: 查询月份 $yearMonth, 使用模式 $datePattern",
    );

    // 查询指定月份、类型为支出的交易，按类别分组并计算总额
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT categoryName, SUM(amount) as total
      FROM transactions
      WHERE type = ? AND date LIKE ?
      GROUP BY categoryName
    ''',
      ['支出', datePattern],
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
}
