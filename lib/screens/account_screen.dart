import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart'; // 导入Transaction模型
import '../utils/formatter.dart'; // 导入格式化工具
import '../providers/transaction_provider.dart'; // 添加导入TransactionProvider
import '../providers/theme_provider.dart'; // 添加导入ThemeProvider
import 'account_detail_screen.dart'; // 导入账户详情页面
import 'package:flutter/cupertino.dart'; // 需要 Cupertino 图标
import '../widgets/common/toast_message.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    // 确保在构建时初始化交易数据
    Future.microtask(() {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadMonthlyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Consumer<AccountProvider>(
          builder: (context, accountProvider, child) {
            return CustomScrollView(
              slivers: [
                // 标题栏
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '账户管理',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '总资产: ${CurrencyFormatter.format(accountProvider.totalAssets)}',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 账户总览卡片
                SliverToBoxAdapter(
                  child: Consumer<TransactionProvider>(
                    builder: (context, transactionProvider, child) {
                      return _buildTotalAssetsCard(
                        accountProvider.totalAssets,
                        transactionProvider.monthlyIncome,
                        transactionProvider.monthlyExpense,
                      );
                    },
                  ),
                ),

                // 账户列表标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '我的账户',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddAccountDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('添加'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 账户列表
                accountProvider.isLoading
                    ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                    : accountProvider.accounts.isEmpty
                    ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            '暂无账户，请点击"添加"按钮创建',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                    : SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final account = accountProvider.accounts[index];
                          return _buildAccountCard(account);
                        }, childCount: accountProvider.accounts.length),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalAssetsCard(
    double totalAssets,
    double monthlyIncome,
    double monthlyExpense,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context); // 获取主题提供者
    final themeColor = themeProvider.themeColor; // 获取当前主题颜色

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: themeColor, // 使用主题颜色
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.3), // 使用主题颜色
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  '总资产',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              CurrencyFormatter.format(totalAssets), // 使用格式化工具
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAssetSummaryItem(
                  '本月收入',
                  monthlyIncome,
                  Colors.greenAccent,
                ),
                const SizedBox(width: 24),
                _buildAssetSummaryItem(
                  '本月支出',
                  monthlyExpense,
                  Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetSummaryItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              CurrencyFormatter.format(amount), // 使用格式化工具
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountCard(Account account) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    IconData accountIcon = Icons.account_balance_wallet_outlined;
    Color accountColor = AppColors.primary;

    switch (account.icon) {
      case 'wallet':
        accountIcon = Icons.account_balance_wallet_outlined;
        break;
      case 'mobile-screen':
        accountIcon = Icons.smartphone_outlined;
        break;
      case 'credit-card':
        accountIcon = Icons.credit_card_outlined;
        break;
      case 'money-bill-trend-up':
        accountIcon = Icons.trending_up_outlined;
        break;
      case 'wechat':
        accountIcon = Icons.chat_bubble_outline;
        break;
      case 'alipay':
        accountIcon = Icons.account_balance_outlined;
        break;
      default:
        accountIcon = Icons.account_balance_wallet_outlined;
    }

    if (account.color != null) {
      try {
        accountColor = Color(int.parse(account.color!));
      } catch (e) {
        accountColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountDetailScreen(account: account),
              ),
            );
          },
          onLongPress: () {
            _showEditAccountDialog(context, account);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(accountIcon, color: accountColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.isDebt ? '信用额度' : '当前余额',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(account.balance), // 使用格式化工具
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            account.balance < 0
                                ? AppColors.expense
                                : AppColors.income,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAccountDialog(BuildContext pageContext, Account account) {
    final isDarkMode = Theme.of(pageContext).brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController(
      text: account.name,
    );
    bool isDebt = account.isDebt;

    showCupertinoDialog(
      context: pageContext,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return CupertinoAlertDialog(
                title: const Text('编辑账户'),
                content: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoTextField(
                          controller: nameController,
                          placeholder: '账户名称',
                          clearButtonMode: OverlayVisibilityMode.editing,
                          autocorrect: false,
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]?.withOpacity(0.5)
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '当前余额',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(account.balance),
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '(通过"调整余额"功能修改)',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextSecondary
                                            .withOpacity(0.7)
                                        : AppColors.textSecondary.withOpacity(
                                          0.7,
                                        ),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '这是一个负债账户',
                              style: TextStyle(fontSize: 15),
                            ),
                            CupertinoSwitch(
                              value: isDebt,
                              activeTrackColor: AppColors.primary,
                              onChanged: (value) {
                                setStateDialog(() {
                                  isDebt = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                  CupertinoDialogAction(
                    child: const Text('调整余额'),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showAdjustBalanceDialog(pageContext, account);
                    },
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('保存属性'),
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ToastMessage.show(
                          dialogContext,
                          '请输入账户名称',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                        return;
                      }

                      final updatedAccount = Account(
                        id: account.id,
                        name: nameController.text,
                        balance: account.balance,
                        isDebt: isDebt,
                        type: account.type,
                        color: account.color,
                        icon: account.icon,
                      );

                      final accountProvider = Provider.of<AccountProvider>(
                        pageContext,
                        listen: false,
                      );

                      final success = await accountProvider.updateAccount(
                        updatedAccount,
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      if (!success) {
                        ToastMessage.show(
                          pageContext,
                          accountProvider.error ?? '更新账户失败',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                      } else {
                        ToastMessage.show(
                          pageContext,
                          '账户属性已保存',
                          icon: Icons.check_circle_outline,
                          backgroundColor: Colors.green.withOpacity(0.9),
                        );
                      }
                    },
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('删除'),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showDeleteAccountDialog(pageContext, account);
                    },
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext pageContext, Account account) {
    final isDarkMode = Theme.of(pageContext).brightness == Brightness.dark;
    bool deleteTransactions = true; // 默认选中删除关联交易记录

    showDialog(
      context: pageContext,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
                title: Text(
                  '删除账户',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '确定要删除"${account.name}"吗？此操作无法撤销。',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 添加删除关联交易记录的选项
                    Row(
                      children: [
                        Checkbox(
                          value: deleteTransactions,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              deleteTransactions = value ?? true;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            '同时删除该账户的所有交易记录',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (deleteTransactions)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                        child: Text(
                          '警告：所有与该账户相关的交易记录将被永久删除！',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (account.id == null) return;
                      final accountProvider = Provider.of<AccountProvider>(
                        pageContext,
                        listen: false,
                      );

                      print("Attempting to delete account ID: ${account.id}");

                      final success = await accountProvider.deleteAccount(
                        account.id!,
                        deleteTransactions: deleteTransactions,
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      if (success) {
                        ToastMessage.show(
                          pageContext,
                          deleteTransactions ? '账户及其交易记录已删除' : '账户已删除，交易记录已保留',
                          icon: Icons.check_circle_outline,
                          backgroundColor: Colors.green.withOpacity(0.9),
                        );
                        print(
                          "Account ID: ${account.id} deleted successfully.",
                        );
                      } else {
                        print(
                          "Failed to delete account ID: ${account.id}. Error: ${accountProvider.error}",
                        );
                        ToastMessage.show(
                          pageContext,
                          accountProvider.error ?? '删除账户失败',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                      }
                    },
                    child: const Text(
                      '删除',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    bool isDebt = false;
    String accountType = 'normal';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
                title: Text(
                  '添加账户',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: '账户名称',
                          hintText: '例如：现金、支付宝',
                          labelStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary.withOpacity(
                                      0.5,
                                    )
                                    : AppColors.textSecondary.withOpacity(0.5),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: balanceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: '初始余额',
                          hintText: '请输入初始余额',
                          prefixText: '¥',
                          labelStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary.withOpacity(
                                      0.5,
                                    )
                                    : AppColors.textSecondary.withOpacity(0.5),
                          ),
                          prefixStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: '账户类型',
                          labelStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        dropdownColor:
                            isDarkMode ? AppColors.darkSurface : Colors.white,
                        value: accountType,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text(
                              '普通账户',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text(
                              '现金账户',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text(
                              '信用卡',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            accountType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: isDebt,
                            checkColor: Colors.white,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                isDebt = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              '这是一个负债账户（如信用卡）',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ToastMessage.show(
                          context,
                          '请输入账户名称',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                        return;
                      }

                      final balance = double.tryParse(balanceController.text);
                      if (balance == null) {
                        ToastMessage.show(
                          context,
                          '请输入有效的余额',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                        return;
                      }

                      final account = Account(
                        name: nameController.text,
                        balance: balance,
                        isDebt: isDebt,
                        type: accountType,
                        color: '0xFF4CAF50',
                        icon:
                            accountType == 'credit' ? 'credit-card' : 'wallet',
                      );

                      final success = await Provider.of<AccountProvider>(
                        context,
                        listen: false,
                      ).addAccount(account);

                      Navigator.pop(context);
                    },
                    child: const Text(
                      '添加',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAdjustBalanceDialog(BuildContext pageContext, Account account) {
    final isDarkMode = Theme.of(pageContext).brightness == Brightness.dark;
    final TextEditingController targetBalanceController =
        TextEditingController();
    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>(); // Form 在 Cupertino 中不常用，可以用简单的校验

    showCupertinoDialog(
      // 改为 Cupertino 对话框
      context: pageContext,
      builder: (dialogContext) {
        // 使用 local state 管理 targetBalanceController 的错误状态
        String? validationError;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return CupertinoAlertDialog(
              title: Text('调整"${account.name}"余额'),
              content: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前余额: ${CurrencyFormatter.format(account.balance)}',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      // 使用 CupertinoTextField
                      controller: targetBalanceController,
                      placeholder: '调整后余额',
                      prefix: const Padding(
                        // 添加前缀 ¥
                        padding: EdgeInsets.only(left: 8.0, right: 4.0),
                        child: Text('¥'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      clearButtonMode: OverlayVisibilityMode.editing,
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          // 根据是否有错误显示不同边框颜色
                          color:
                              validationError != null
                                  ? Colors.red
                                  : isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onChanged: (_) {
                        // 输入变化时清除错误状态
                        if (validationError != null) {
                          setStateDialog(() {
                            validationError = null;
                          });
                        }
                      },
                    ),
                    // 显示校验错误信息
                    if (validationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                        child: Text(
                          validationError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '将自动生成一条"余额调整"的交易记录。',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? AppColors.darkTextSecondary.withOpacity(0.7)
                                : AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('确认调整'),
                  onPressed: () async {
                    // 手动校验
                    final value = targetBalanceController.text;
                    if (value.isEmpty) {
                      setStateDialog(() {
                        validationError = '请输入调整后的余额';
                      });
                      return;
                    }
                    final targetBalance = double.tryParse(value);
                    if (targetBalance == null) {
                      setStateDialog(() {
                        validationError = '请输入有效的数字';
                      });
                      return;
                    }
                    // 清除可能存在的旧错误
                    setStateDialog(() {
                      validationError = null;
                    });

                    final currentBalance = account.balance;
                    final adjustmentAmount = targetBalance - currentBalance;

                    if (adjustmentAmount == 0) {
                      Navigator.pop(dialogContext);
                      ToastMessage.show(
                        pageContext,
                        '余额未改变，无需调整',
                        icon: Icons.info_outline,
                        backgroundColor: Theme.of(
                          pageContext,
                        ).primaryColor.withOpacity(0.9),
                      );
                      return;
                    }

                    // --- 定义调整类型和类别信息 ---
                    const String transactionType = '调整'; // 新类型
                    final double amount = adjustmentAmount; // 直接使用带符号的金额
                    const String adjustmentCategoryName = '余额调整';
                    const int adjustmentCategoryId = -1;
                    const String adjustmentCategoryIcon = 'tune';
                    const String adjustmentCategoryColor = '0xFF9E9E9E';
                    final String note =
                        '调整账户余额至 ${CurrencyFormatter.format(targetBalance)}';
                    // --- 修改结束 ---

                    final adjustmentTransaction = Transaction(
                      type: transactionType,
                      amount: amount, // 直接存储带符号的调整金额
                      categoryId: adjustmentCategoryId,
                      categoryName: adjustmentCategoryName,
                      categoryIcon: adjustmentCategoryIcon,
                      categoryColor: adjustmentCategoryColor,
                      accountId: account.id!,
                      accountName: account.name,
                      date: DateTime.now(),
                      note: note,
                    );

                    try {
                      // 使用 pageContext 访问 Provider
                      final txProvider = Provider.of<TransactionProvider>(
                        pageContext,
                        listen: false,
                      );
                      final accountProvider = Provider.of<AccountProvider>(
                        pageContext,
                        listen: false,
                      );

                      // 调用 addTransaction (已包含 syncAccountBalances)
                      final success = await txProvider.addTransaction(
                        adjustmentTransaction,
                        context: pageContext, // 传递 context
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext); // 关闭调整余额对话框

                      if (success) {
                        if (pageContext.mounted) {
                          ToastMessage.show(
                            pageContext,
                            '余额调整成功',
                            icon: Icons.check_circle_outline,
                            backgroundColor: Colors.green.withOpacity(0.9),
                          );
                        }
                      } else {
                        if (pageContext.mounted) {
                          ToastMessage.show(
                            pageContext,
                            txProvider.error ?? '添加调整记录失败',
                            icon: Icons.error_outline,
                            backgroundColor: Colors.red.withOpacity(0.9),
                          );
                        }
                      }
                    } catch (e) {
                      print("Error adding adjustment transaction: $e");
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext); // 出错也关闭对话框
                        ToastMessage.show(
                          pageContext,
                          '处理调整记录时出错',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
