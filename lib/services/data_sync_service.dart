import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../services/transaction_service.dart';
import '../utils/date_util.dart';

class DataSyncService {
  // 单例模式
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  // 同步所有数据（用于应用启动或全局刷新）
  Future<void> syncAllData(BuildContext context) async {
    try {
      print('======== 开始同步所有数据 ========');

      // 获取所有Provider
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final budgetProvider = Provider.of<BudgetProvider>(
        context,
        listen: false,
      );

      // 1. 先同步账户余额
      await accountProvider.accountService.syncAccountBalances();

      // 2. 刷新账户数据（包括总资产）
      await accountProvider.syncData();

      // 3. 刷新交易数据
      await transactionProvider.initData();

      // 4. 刷新分类数据
      await categoryProvider.initCategories();

      // 5. 刷新预算数据
      await budgetProvider.initBudgets();

      print('======== 所有数据同步完成 ========');
    } catch (e) {
      print('同步所有数据失败: $e');
    }
  }

  // 同步交易相关数据（用于添加/更新/删除交易后）
  Future<void> syncTransactionRelatedData(BuildContext context) async {
    try {
      print('======== 开始同步交易相关数据 ========');

      // 获取Provider
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // 1. 先同步账户余额 - 确保所有账户余额正确
      print('1. 同步账户余额');
      await accountProvider.accountService.syncAccountBalances();

      // 2. 强制重新计算总资产 - 添加这一步确保总资产更新
      print('2. 强制重新计算总资产');
      final totalAssets = await accountProvider.accountService.getTotalAssets();
      print('   计算得到总资产: $totalAssets');

      // 3. 刷新账户数据（包括总资产）
      print('3. 刷新账户数据');
      await accountProvider.syncData();

      // 4. 获取当前月份并格式化
      final now = DateTime.now();
      final currentMonth = DateUtil.getMonthString(now);
      print('4. 当前月份: $currentMonth');

      // 5. 确保当前月份设置正确
      await transactionProvider.setCurrentMonth(currentMonth);

      // 6. 强制完整刷新交易数据
      print('5. 完全刷新交易数据');
      await transactionProvider.initData();
      await transactionProvider.loadMonthlyData();

      print('======== 交易相关数据同步完成 ========');
    } catch (e) {
      print('同步交易相关数据出错: $e');
    }
  }

  // 同步统计页面数据
  Future<void> syncStatisticsData(
    BuildContext context,
    DateTime selectedDate,
  ) async {
    try {
      print('======== 开始同步统计数据 ========');

      // 获取Provider
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // 1. 先同步账户余额
      await accountProvider.accountService.syncAccountBalances();

      // 2. 刷新账户数据
      await accountProvider.syncData();

      // 3. 设置当前月份并加载月度数据
      final currentMonth =
          '${selectedDate.year}${selectedDate.month.toString().padLeft(2, '0')}';
      transactionProvider.setCurrentMonth(currentMonth);
      await transactionProvider.loadMonthlyData();

      print('======== 统计数据同步完成 ========');
    } catch (e) {
      print('同步统计数据失败: $e');
    }
  }
}
