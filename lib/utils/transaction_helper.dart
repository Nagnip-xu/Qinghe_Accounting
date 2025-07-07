import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../services/transaction_service.dart';
import '../utils/toast_message.dart';

class TransactionHelper {
  /// 添加交易并处理相关账户余额更新
  static Future<bool> addTransaction(
    BuildContext context,
    Transaction transaction,
  ) async {
    try {
      // 获取Providers
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      // 添加交易
      final success = await transactionProvider.addTransaction(transaction);

      if (success) {
        // 同步账户余额
        await accountProvider.syncData();

        // 返回成功
        return true;
      } else {
        // 显示错误信息
        if (context.mounted) {
          ToastMessage.show(
            context,
            transactionProvider.error ?? '添加交易失败',
            icon: Icons.error_outline,
            backgroundColor: Colors.red.withOpacity(0.9),
          );
        }
        return false;
      }
    } catch (e) {
      // 显示异常信息
      if (context.mounted) {
        ToastMessage.show(
          context,
          '添加交易失败: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
      return false;
    }
  }

  /// 更新交易并处理相关账户余额更新
  static Future<bool> updateTransaction(
    BuildContext context,
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    try {
      // 获取Providers
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      // 更新交易
      final success = await transactionProvider.updateTransaction(
        oldTransaction,
        newTransaction,
      );

      if (success) {
        // 同步账户余额
        await accountProvider.syncData();

        // 返回成功
        return true;
      } else {
        // 显示错误信息
        if (context.mounted) {
          ToastMessage.show(
            context,
            transactionProvider.error ?? '更新交易失败',
            icon: Icons.error_outline,
            backgroundColor: Colors.red.withOpacity(0.9),
          );
        }
        return false;
      }
    } catch (e) {
      // 显示异常信息
      if (context.mounted) {
        ToastMessage.show(
          context,
          '更新交易失败: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
      return false;
    }
  }

  /// 删除交易并处理相关账户余额更新
  static Future<bool> deleteTransaction(
    BuildContext context,
    Transaction transaction,
  ) async {
    try {
      // 获取Providers
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      // 删除交易
      final success = await transactionProvider.deleteTransaction(transaction);

      if (success) {
        // 同步账户余额
        await accountProvider.syncData();

        // 返回成功
        return true;
      } else {
        // 显示错误信息
        if (context.mounted) {
          ToastMessage.show(
            context,
            transactionProvider.error ?? '删除交易失败',
            icon: Icons.error_outline,
            backgroundColor: Colors.red.withOpacity(0.9),
          );
        }
        return false;
      }
    } catch (e) {
      // 显示异常信息
      if (context.mounted) {
        ToastMessage.show(
          context,
          '删除交易失败: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
      return false;
    }
  }

  /// 获取指定账户的交易记录
  static Future<List<Transaction>> getAccountTransactions(
    BuildContext context,
    int accountId,
  ) async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // 先尝试从Provider中获取
      List<Transaction> cachedTransactions = transactionProvider
          .getAccountTransactions(accountId);

      // 如果缓存中没有，则从服务中加载
      if (cachedTransactions.isEmpty) {
        await transactionProvider.fetchTransactionsByAccount(accountId);
        cachedTransactions = transactionProvider.getAccountTransactions(
          accountId,
        );
      }

      return cachedTransactions;
    } catch (e) {
      // 出错时返回空列表
      print('获取账户交易记录失败: $e');
      return [];
    }
  }
}
