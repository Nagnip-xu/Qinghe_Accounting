import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../constants/colors.dart';
import '../providers/transaction_provider.dart';
import '../screens/budget_screen.dart';
import '../providers/account_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../screens/login_screen.dart';
import '../utils/toast_message.dart';
import 'package:flutter/foundation.dart'; // 添加kDebugMode的引用
import '../services/backup_service.dart'; // 添加BackupService
// 添加BackupSelectionDialog
import '../screens/financial_goals_screen.dart';
import '../providers/reminder_provider.dart';
import '../widgets/bill_reminder_dialog.dart';
import '../screens/settings_screen.dart'; // 添加设置页面的导入
import 'package:flutter/services.dart'; // 添加SystemNavigator的引用
import 'package:shared_preferences/shared_preferences.dart'; // 添加SharedPreferences的引用
import '../screens/feature_documentation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 主题选项
  final List<String> _themeOptions = ['默认', '浅色', '深色'];
  final String _selectedTheme = '默认';

  // 语言选项
  final List<String> _languageOptions = ['简体中文', 'English'];
  String _selectedLanguage = '简体中文';

  @override
  Widget build(BuildContext context) {
    // 使用UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final User currentUser = userProvider.currentUser;
    final bool isLoggedIn = userProvider.isLoggedIn;
    // 获取当前主题亮暗模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 获取本地化文本
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.profile ?? '个人中心',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        // 跳转到设置页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 用户信息卡片
              _buildUserInfoCard(userProvider),

              const SizedBox(height: 24),

              // 财务管理
              _buildSectionTitle(l10n.budgetManagement ?? '财务管理'),
              _buildFeatureGroup([
                _FeatureItem(
                  icon: Icons.savings_outlined,
                  title: l10n.categoryBudget ?? '我的预算',
                  onTap: () {
                    // 打开预算管理页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                ),
                _FeatureItem(
                  icon: Icons.trending_up,
                  title: '收支目标',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FinancialGoalsScreen(),
                        ),
                      ),
                ),
                _FeatureItem(
                  icon: Icons.notifications_outlined,
                  title: '账单提醒',
                  onTap: () => _showBillReminderDialog(),
                ),
              ]),

              const SizedBox(height: 24),

              // 数据管理
              _buildSectionTitle(l10n.dataBackup ?? '数据管理'),
              _buildFeatureGroup([
                _FeatureItem(
                  icon: Icons.backup_outlined,
                  title: l10n.backup ?? '数据备份',
                  onTap: () => _backupData(),
                ),
                _FeatureItem(
                  icon: Icons.restore_outlined,
                  title: l10n.restore ?? '数据恢复',
                  onTap: () => _performDataRestore(),
                ),
                _FeatureItem(
                  icon: Icons.insert_drive_file_outlined,
                  title: l10n.exportData ?? '导出报表',
                  onTap: () => _exportTransactionData(context),
                ),
              ]),

              const SizedBox(height: 24),

              // 应用设置
              _buildSectionTitle(l10n.settings ?? '应用设置'),
              _buildFeatureGroup([
                _FeatureItem(
                  icon: Icons.color_lens_outlined,
                  title: l10n.themeSettings ?? '主题设置',
                  onTap: () => _showThemeSettingsDialog(),
                ),
                _FeatureItem(
                  icon: Icons.language_outlined,
                  title: l10n.languageSettings ?? '语言设置',
                  onTap: () => _showLanguageSettingsDialog(),
                ),
                _FeatureItem(
                  icon: Icons.help_outline,
                  title: '帮助文档',
                  onTap: () => _showDocumentationHome(context),
                ),
                _FeatureItem(
                  icon: Icons.info_outline,
                  title: l10n.aboutApp ?? '关于应用',
                  onTap: () => _showAboutDialog(context),
                ),
              ]),

              // 版本信息
              const SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '青禾记账 v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(UserProvider userProvider) {
    final user = userProvider.currentUser;
    final isLoggedIn = userProvider.isLoggedIn;
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context); // 获取主题提供者
    final themeColor = themeProvider.themeColor; // 获取当前主题颜色

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          isLoggedIn
              ? Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: themeColor.withOpacity(0.2), // 使用主题颜色
                    child: Text(
                      user.username.isEmpty
                          ? '?'
                          : user.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeColor, // 使用主题颜色
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: themeColor.withOpacity(0.2), // 使用主题颜色
                    child: Text(
                      '用',
                      style: TextStyle(
                        color: themeColor, // 使用主题颜色
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notLoggedIn ?? '未登录',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.loginToSyncData ?? '点击登录账号，同步您的数据',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor, // 使用主题颜色
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(l10n.login ?? '登录'),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFeatureGroup(List<_FeatureItem> items) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, color: themeColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.title,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color:
                              theme.brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: theme.dividerColor,
                  indent: 56,
                  endIndent: 0,
                ),
            ],
          );
        }),
      ),
    );
  }

  // 登录对话框
  void _showLoginDialog(UserProvider userProvider) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('用户登录'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名',
                          hintText: '输入: admin, test 或 user',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '密码',
                          hintText: 'admin用户密码为admin123',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !isLoading,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : TextButton(
                        onPressed: () async {
                          // 校验输入
                          if (usernameController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            setState(() {
                              errorMessage = '用户名和密码不能为空';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          // 尝试登录
                          final success = await userProvider.login(
                            usernameController.text,
                            passwordController.text,
                          );

                          if (success) {
                            Navigator.pop(context);
                            // 使用新的ToastMessage替代SnackBar
                            ToastMessage.show(
                              context,
                              '登录成功',
                              icon: Icons.check_circle_outline,
                              backgroundColor: Colors.green.withOpacity(0.9),
                            );
                          } else {
                            setState(() {
                              isLoading = false;
                              errorMessage = userProvider.error ?? '用户名或密码错误';
                            });
                          }
                        },
                        child: const Text('登录'),
                      ),
                ],
              );
            },
          ),
    );
  }

  // 退出登录
  Future<void> _logout(UserProvider userProvider) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('退出登录'),
                content: const Text('确定要退出登录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确定'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      final success = await userProvider.logout();
      if (success) {
        // 使用新的ToastMessage替代SnackBar
        ToastMessage.show(
          context,
          '已退出登录',
          icon: Icons.exit_to_app,
          backgroundColor: Colors.blue.withOpacity(0.9),
        );
      } else {
        // 使用新的ToastMessage替代SnackBar
        ToastMessage.show(
          context,
          userProvider.error ?? '退出登录失败',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    }
  }

  // 收支目标对话框
  void _showFinancialGoalsDialog() {
    // 直接导航到财务目标页面
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinancialGoalsScreen()),
    );
  }

  // 账单提醒对话框
  void _showBillReminderDialog() async {
    final reminderProvider = Provider.of<ReminderProvider>(
      context,
      listen: false,
    );
    await reminderProvider.refreshSettings();

    // 检查通知权限
    if (!reminderProvider.hasPermission) {
      // 首次使用时显示通知权限说明
      final firstUse = await _isFirstTimeUsingReminders();

      if (firstUse) {
        // 显示功能介绍对话框，解释权限用途
        final proceedWithRequest = await _showReminderIntroductionDialog();
        if (!proceedWithRequest) {
          // 用户选择不继续
          return;
        }
      }

      // 需要先请求权限
      final granted = await _showPermissionRequestDialog(reminderProvider);
      if (!granted) {
        ToastMessage.show(
          context,
          '需要通知权限才能设置提醒',
          icon: Icons.warning,
          backgroundColor: Colors.orange.withOpacity(0.9),
        );
        return;
      }
    }

    // 显示提醒设置对话框
    showDialog(
      context: context,
      builder:
          (context) => ChangeNotifierProvider.value(
            value: reminderProvider,
            child: const BillReminderDialog(),
          ),
    );
  }

  // 检查是否首次使用提醒功能
  Future<bool> _isFirstTimeUsingReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstUse = prefs.getBool('first_time_reminders') ?? true;

      if (firstUse) {
        // 标记为非首次使用
        await prefs.setBool('first_time_reminders', false);
      }

      return firstUse;
    } catch (e) {
      print('检查首次使用状态出错: $e');
      return false;
    }
  }

  // 显示提醒功能介绍对话框
  Future<bool> _showReminderIntroductionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 10),
                    const Text('账单提醒功能'),
                  ],
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('青禾记账支持账单到期提醒功能，可以在账单到期前提醒您及时付款。'),
                    SizedBox(height: 16),
                    Text('此功能需要发送通知到您的设备，需要您授予通知权限。'),
                    SizedBox(height: 8),
                    Text('您可以随时在应用设置中管理通知权限。'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('暂不使用'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('继续'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // 显示权限请求对话框
  Future<bool> _showPermissionRequestDialog(ReminderProvider provider) async {
    // 显示对话框
    final bool showSettings =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('通知权限请求'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('青禾记账需要通知权限来发送账单提醒'),
                    SizedBox(height: 12),
                    Text('请在接下来的系统对话框中点击"允许"以启用通知'),
                    SizedBox(height: 8),
                    Text(
                      '注意：如果您点击"拒绝"，将无法收到账单到期提醒',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('继续'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!showSettings) {
      return false;
    }

    // 请求权限
    try {
      // 显示请求中对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              title: Text('请求通知权限'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在请求权限，请稍候...'),
                  SizedBox(height: 8),
                  Text('请允许系统权限请求以启用提醒功能', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
      );

      // 请求权限
      final result = await provider.requestNotificationPermission();

      // 关闭对话框
      Navigator.of(context).pop();

      if (result) {
        ToastMessage.show(
          context,
          '通知权限已授予，您将收到账单到期提醒',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.withOpacity(0.9),
        );
      }

      return result;
    } catch (e) {
      // 关闭进度对话框（如果存在）
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('请求权限出错: $e');
      return false;
    }
  }

  // 数据备份
  void _backupData() async {
    try {
      // 检查权限
      if (!await _checkAndRequestPermissions()) {
        ToastMessage.show(
          context,
          '需要存储权限才能备份数据',
          icon: Icons.warning,
          backgroundColor: Colors.orange.withOpacity(0.9),
        );
        return;
      }

      // 添加确认对话框
      final bool confirmBackup =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('确认备份'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('确定要立即备份您的数据吗？'),
                      SizedBox(height: 12),
                      Text(
                        '备份将保存您的所有账户、交易和设置数据。',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确认备份'),
                    ),
                  ],
                ),
          ) ??
          false;

      // 如果用户取消，则不执行备份
      if (!confirmBackup) return;

      // 显示备份中对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              title: Text('数据备份'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在备份数据，请稍候...'),
                ],
              ),
            ),
      );

      // 实际执行备份操作
      final backupPath = await BackupService.backupDatabase();

      // 获取备份文件大小
      final backupFile = File(backupPath);
      final fileSize = await backupFile.length();
      final fileSizeStr =
          fileSize < 1024 * 1024
              ? '${(fileSize / 1024).toStringAsFixed(2)} KB'
              : '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';

      // 备份成功后关闭进度对话框
      if (mounted) Navigator.pop(context);

      // 获取最新的备份时间
      final lastBackup = await BackupService.getLastBackupTime();
      String backupTimeString = "刚刚";

      if (lastBackup != null) {
        final now = DateTime.now();
        final difference = now.difference(lastBackup);

        if (difference.inDays > 0) {
          backupTimeString = '${difference.inDays}天前';
        } else if (difference.inHours > 0) {
          backupTimeString = '${difference.inHours}小时前';
        } else if (difference.inMinutes > 0) {
          backupTimeString = '${difference.inMinutes}分钟前';
        } else {
          backupTimeString = '刚刚';
        }
      }

      // 显示备份成功对话框
      if (mounted) {
        // 显示备份成功对话框
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('备份成功'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('数据已成功备份到手机下载目录'),
                    const SizedBox(height: 8),
                    Text('文件名：${backupPath.split('/').last}'),
                    Text('文件大小：$fileSizeStr'),
                    Text(
                      '备份时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '上次备份时间: $backupTimeString',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '您可以在手机文件管理器中的"下载/青禾记账/备份"文件夹找到备份文件',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                  TextButton(
                    onPressed: () {
                      try {
                        Navigator.pop(context);
                        ToastMessage.show(
                          context,
                          '备份文件位于手机下载目录中的"青禾记账/备份"文件夹',
                          icon: Icons.folder_open,
                          backgroundColor: Colors.blue.withOpacity(0.9),
                        );
                      } catch (e) {
                        ToastMessage.show(
                          context,
                          '无法定位文件: $e',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                      }
                    },
                    child: const Text('查看位置'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('备份失败: $e');
      }

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误提示
      ToastMessage.show(
        context,
        '备份失败: $e',
        icon: Icons.error_outline,
        backgroundColor: Colors.red.withOpacity(0.9),
      );
    }
  }

  // 数据恢复
  void _performDataRestore() async {
    try {
      // 检查权限
      if (!await _checkAndRequestPermissions()) {
        ToastMessage.show(
          context,
          '需要存储权限才能恢复数据',
          icon: Icons.warning,
          backgroundColor: Colors.orange.withOpacity(0.9),
        );
        return;
      }

      // 获取所有备份文件
      final backupFiles = await BackupService.getAllBackups();

      if (backupFiles.isEmpty) {
        ToastMessage.show(
          context,
          '没有找到备份文件',
          icon: Icons.error,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
        return;
      }

      // 显示备份文件选择对话框
      final selectedBackupPath = await showDialog<String>(
        context: context,
        builder:
            (BuildContext context) =>
                BackupSelectionDialog(backupFiles: backupFiles),
      );

      if (selectedBackupPath != null) {
        // 显示恢复确认对话框
        final confirmRestore = await showDialog<bool>(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('确认恢复'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('从备份恢复将会覆盖当前所有数据，此操作不可撤销。'),
                    SizedBox(height: 12),
                    Text(
                      '注意: 恢复前将自动备份当前数据，以便需要时可以恢复。',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '恢复后需要重启应用才能看到恢复的数据。',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('确定要继续吗？'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('恢复'),
                  ),
                ],
              ),
        );

        if (confirmRestore == true) {
          // 显示恢复进度对话框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (BuildContext context) => const AlertDialog(
                  title: Text('正在恢复'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在恢复数据，请勿关闭应用...'),
                    ],
                  ),
                ),
          );

          try {
            // 执行实际恢复操作
            final success = await BackupService.restoreDatabase(
              selectedBackupPath,
            );

            // 恢复完成后关闭进度对话框
            if (mounted) Navigator.pop(context);

            if (success) {
              // 显示恢复成功对话框
              showDialog(
                context: context,
                barrierDismissible: false, // 防止用户点击外部关闭
                builder:
                    (BuildContext context) => AlertDialog(
                      title: const Text('恢复成功'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('数据已成功从备份文件恢复'),
                          const SizedBox(height: 8),
                          Text(
                            '恢复时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '⚠️ 重要提示 ⚠️',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '您必须完全退出并重新启动应用才能看到恢复的数据。请按照以下步骤操作：',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. 点击"退出应用"按钮\n'
                            '2. 从最近任务中移除本应用\n'
                            '3. 重新打开应用',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // 提示用户手动退出应用
                            Navigator.pop(context);
                            ToastMessage.show(
                              context,
                              '请完全退出并重新打开应用以加载恢复的数据',
                              icon: Icons.exit_to_app,
                              backgroundColor: Colors.blue.withOpacity(0.9),
                            );
                          },
                          child: const Text('稍后退出'),
                        ),
                        TextButton(
                          onPressed: () {
                            // 退出应用
                            Navigator.pop(context);
                            ToastMessage.show(
                              context,
                              '请完全关闭并重新打开应用以加载恢复的数据',
                              icon: Icons.exit_to_app,
                              backgroundColor: Colors.red.withOpacity(0.9),
                            );
                            // 如果是 Android，可以使用 SystemNavigator.pop()
                            if (Platform.isAndroid) {
                              SystemNavigator.pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('退出应用'),
                        ),
                      ],
                    ),
              );
            } else {
              ToastMessage.show(
                context,
                '恢复失败，请确保备份文件完整',
                icon: Icons.error,
                backgroundColor: Colors.red.withOpacity(0.9),
              );
            }
          } catch (e) {
            // 恢复失败后关闭进度对话框
            if (mounted) Navigator.pop(context);

            ToastMessage.show(
              context,
              '恢复失败: $e',
              icon: Icons.error,
              backgroundColor: Colors.red.withOpacity(0.9),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('恢复操作失败: $e');
      }

      ToastMessage.show(
        context,
        '获取备份文件失败: $e',
        icon: Icons.error,
        backgroundColor: Colors.red.withOpacity(0.9),
      );
    }
  }

  // 检查并请求存储权限
  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // 简化权限检查，避免使用permission_handler插件
        // 直接尝试创建目录，如果可以创建则表示有权限
        final directory = Directory('/storage/emulated/0/Download/青禾记账');
        try {
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return true;
        } catch (e) {
          if (kDebugMode) {
            print('创建目录失败，可能没有权限: $e');
          }

          // 如果创建目录失败，提示用户手动授予权限
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('需要存储权限'),
                  content: const Text('请到设置中授予青禾记账读写存储的权限，以便进行数据备份和导出。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('确定'),
                    ),
                  ],
                ),
          );
          return false;
        }
      }
      // iOS或其他平台不需要特别权限
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('权限检查过程发生错误: $e');
      }
      return false;
    }
  }

  // 获取导出目录 - 使用下载目录
  Future<String> _getExportDirectory() async {
    try {
      // 确保目录存在
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download/青禾记账/导出报表');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      }

      // iOS或其他平台使用应用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${docDir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir.path;
    } catch (e) {
      if (kDebugMode) {
        print('获取导出目录失败，将使用应用目录: $e');
      }

      // 出错时使用应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${appDir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir.path;
    }
  }

  // 导出交易数据到CSV文件
  void _exportTransactionData(BuildContext context) async {
    try {
      // 检查权限
      if (!await _checkAndRequestPermissions()) {
        return;
      }

      // 显示准备数据对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (BuildContext context) => const AlertDialog(
              title: Text('准备数据'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在准备导出数据，请稍候...'),
                ],
              ),
            ),
      );

      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      // 确保获取所有交易数据
      await transactionProvider.fetchAllTransactions();
      final allTransactions = transactionProvider.transactions;

      // 关闭准备数据对话框
      if (mounted) Navigator.pop(context);

      // 如果没有交易数据，显示提示
      if (allTransactions.isEmpty) {
        ToastMessage.show(
          context,
          '没有交易数据可以导出',
          icon: Icons.info_outline,
          backgroundColor: Colors.orange.withOpacity(0.9),
        );
        return;
      }

      // 先选择导出格式
      final exportFormat = await showDialog<String>(
        context: context,
        builder:
            (BuildContext context) => AlertDialog(
              title: const Text('选择导出格式'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(Icons.table_chart, color: Colors.green),
                    ),
                    title: const Text('CSV格式'),
                    subtitle: const Text('适用于Excel、Numbers等电子表格软件'),
                    onTap: () => Navigator.pop(context, 'csv'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(Icons.text_snippet, color: Colors.blue),
                    ),
                    title: const Text('文本格式(TXT)'),
                    subtitle: const Text('简单文本格式，适用于所有设备查看'),
                    onTap: () => Navigator.pop(context, 'txt'),
                  ),
                ],
              ),
            ),
      );

      // 如果用户取消选择，则不继续
      if (exportFormat == null) return;

      // 显示导出中对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (BuildContext dialogContext) => const AlertDialog(
              title: Text('导出数据'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在导出数据，请稍候...'),
                ],
              ),
            ),
      );

      // 获取导出目录 (下载目录)
      final exportPath = await _getExportDirectory();

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // 根据选择的格式创建文件名
      final fileName =
          exportFormat == 'csv' ? '交易记录_$dateStr.csv' : '交易记录_$dateStr.txt';

      final file = File('$exportPath/$fileName');

      // 创建内容
      StringBuffer content = StringBuffer();

      // 计算收支统计数据
      double totalIncome = 0;
      double totalExpense = 0;
      double totalTransfer = 0;

      // 按日期分组的数据
      Map<String, List<dynamic>> dailyTransactions = {};

      // 按类别分组的收支数据
      Map<String, double> categoryExpenses = {};
      Map<String, double> categoryIncomes = {};

      // 处理所有交易，计算统计数据
      for (var transaction in allTransactions) {
        // 按类型累计总额
        if (transaction.type == '收入') {
          totalIncome += transaction.amount;

          // 按类别统计收入
          if (categoryIncomes.containsKey(transaction.categoryName)) {
            categoryIncomes[transaction.categoryName] =
                categoryIncomes[transaction.categoryName]! + transaction.amount;
          } else {
            categoryIncomes[transaction.categoryName] = transaction.amount;
          }
        } else if (transaction.type == '支出') {
          totalExpense += transaction.amount;

          // 按类别统计支出
          if (categoryExpenses.containsKey(transaction.categoryName)) {
            categoryExpenses[transaction.categoryName] =
                categoryExpenses[transaction.categoryName]! +
                transaction.amount;
          } else {
            categoryExpenses[transaction.categoryName] = transaction.amount;
          }
        } else if (transaction.type == '转账') {
          totalTransfer += transaction.amount;
        }

        // 按日期分组
        String dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        if (!dailyTransactions.containsKey(dateKey)) {
          dailyTransactions[dateKey] = [];
        }
        dailyTransactions[dateKey]!.add(transaction);
      }

      // 计算净收入（收入-支出）
      double netIncome = totalIncome - totalExpense;

      // 添加文件标题和基本信息
      if (exportFormat == 'csv') {
        // CSV格式
        content.writeln('# 青禾记账 - 交易记录导出');
        content.writeln(
          '# 导出时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
        );
        content.writeln('# 账户总数: ${accountProvider.accounts.length}');
        content.writeln('# 交易总数: ${allTransactions.length}');
        content.writeln(
          '# 总资产: ¥${accountProvider.totalAssets.toStringAsFixed(2)}',
        );
        content.writeln();

        // 添加收支统计详情
        content.writeln('# 收支详情统计');
        content.writeln('# 总收入,总支出,净收入(收入-支出),转账总额');
        content.writeln(
          '# ¥${totalIncome.toStringAsFixed(2)},¥${totalExpense.toStringAsFixed(2)},'
          '¥${netIncome.toStringAsFixed(2)},¥${totalTransfer.toStringAsFixed(2)}',
        );
        content.writeln();

        // 添加类别收支统计
        content.writeln('# 支出类别统计');
        categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..forEach((entry) {
            content.writeln(
              '# ${entry.key},¥${entry.value.toStringAsFixed(2)}',
            );
          });
        content.writeln();

        content.writeln('# 收入类别统计');
        categoryIncomes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..forEach((entry) {
            content.writeln(
              '# ${entry.key},¥${entry.value.toStringAsFixed(2)}',
            );
          });
        content.writeln();

        // 添加表头
        content.writeln('日期,时间,类型,金额,分类,账户,转入账户,备注');

        // 添加交易数据
        for (var transaction in allTransactions) {
          // 处理CSV字段中的特殊字符，确保数据正确导出
          String formatCsvField(String? field) {
            if (field == null) return '';
            // 如果字段包含逗号、引号或换行符，则用引号包裹并处理内部引号
            if (field.contains(',') ||
                field.contains('"') ||
                field.contains('\n')) {
              return '"${field.replaceAll('"', '""')}"';
            }
            return field;
          }

          // 格式化日期时间
          final date = DateFormat('yyyy-MM-dd').format(transaction.date);
          final time = DateFormat('HH:mm:ss').format(transaction.date);

          // 格式化金额为带两位小数的字符串
          final amount = transaction.amount.toStringAsFixed(2);

          // 构建CSV行
          content.writeln(
            '$date,'
            '$time,'
            '${formatCsvField(transaction.type)},'
            '$amount,'
            '${formatCsvField(transaction.categoryName)},'
            '${formatCsvField(transaction.accountName)},'
            '${formatCsvField(transaction.toAccountName ?? '')},'
            '${formatCsvField(transaction.note)}',
          );
        }
      } else {
        // 文本格式（更易读）
        content.writeln('======= 青禾记账 - 交易记录导出 =======');
        content.writeln('');
        content.writeln(
          '导出时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
        );
        content.writeln('账户总数: ${accountProvider.accounts.length}');
        content.writeln('交易总数: ${allTransactions.length}');
        content.writeln(
          '总资产: ¥${accountProvider.totalAssets.toStringAsFixed(2)}',
        );
        content.writeln('');

        // 添加收支统计详情
        content.writeln('======= 收支详情统计 =======');
        content.writeln('总收入: ¥${totalIncome.toStringAsFixed(2)}');
        content.writeln('总支出: ¥${totalExpense.toStringAsFixed(2)}');
        content.writeln('净收入: ¥${netIncome.toStringAsFixed(2)}');
        content.writeln('转账总额: ¥${totalTransfer.toStringAsFixed(2)}');
        content.writeln('');

        // 添加类别统计
        content.writeln('======= 支出类别统计 =======');
        if (categoryExpenses.isEmpty) {
          content.writeln('暂无支出数据');
        } else {
          categoryExpenses.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
            ..forEach((entry) {
              content.writeln(
                '${entry.key}: ¥${entry.value.toStringAsFixed(2)}',
              );
            });
        }
        content.writeln('');

        content.writeln('======= 收入类别统计 =======');
        if (categoryIncomes.isEmpty) {
          content.writeln('暂无收入数据');
        } else {
          categoryIncomes.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
            ..forEach((entry) {
              content.writeln(
                '${entry.key}: ¥${entry.value.toStringAsFixed(2)}',
              );
            });
        }
        content.writeln('');

        // 按日期显示交易明细
        content.writeln('======= 交易记录明细 =======');
        content.writeln('');

        if (dailyTransactions.isEmpty) {
          content.writeln('暂无交易记录');
        } else {
          // 按日期逆序排序（最近的日期在前）
          List<String> sortedDates =
              dailyTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

          for (var dateStr in sortedDates) {
            content.writeln('【$dateStr】');

            // 获取该日期的交易记录
            List<dynamic> dayTransactions = dailyTransactions[dateStr]!;

            // 按时间排序（一天内最近的时间在前）
            dayTransactions.sort((a, b) => b.date.compareTo(a.date));

            // 每日小计
            double dayIncome = 0;
            double dayExpense = 0;

            // 添加交易数据
            for (var transaction in dayTransactions) {
              final time = DateFormat('HH:mm:ss').format(transaction.date);
              final amount = transaction.amount.toStringAsFixed(2);

              // 累计每日收支
              if (transaction.type == '收入') {
                dayIncome += transaction.amount;
              } else if (transaction.type == '支出') {
                dayExpense += transaction.amount;
              }

              content.writeln(
                '${transaction.type} - ¥$amount (${transaction.categoryName})',
              );
              content.writeln('时间: $time');
              content.writeln('账户: ${transaction.accountName}');

              if (transaction.toAccountName != null &&
                  transaction.toAccountName!.isNotEmpty) {
                content.writeln('转入账户: ${transaction.toAccountName}');
              }

              if (transaction.note != null && transaction.note!.isNotEmpty) {
                content.writeln('备注: ${transaction.note}');
              }

              content.writeln('-----------------------');
            }

            // 添加每日小计
            content.writeln(
              '日收入: ¥${dayIncome.toStringAsFixed(2)} | 日支出: ¥${dayExpense.toStringAsFixed(2)} | 净额: ¥${(dayIncome - dayExpense).toStringAsFixed(2)}',
            );
            content.writeln('=============================');
            content.writeln('');
          }
        }
      }

      // 保存文件
      await file.writeAsString(content.toString());

      // 关闭进度对话框
      if (mounted) Navigator.pop(context);

      // 显示导出成功对话框
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('导出成功'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('数据已成功导出到手机下载目录：'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.file_present,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '文件名: $fileName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.folder, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '保存位置: $exportPath',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.insights,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('记录数: ${allTransactions.length}')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.equalizer,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '收支统计: 收入 ¥${totalIncome.toStringAsFixed(2)} / 支出 ¥${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '您可以在手机文件管理器中找到并打开该文件',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    exportFormat == 'csv'
                        ? const Text(
                          '您可以使用Excel、Numbers或其他电子表格软件打开此CSV文件',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                        : const Text(
                          '您可以使用任何文本编辑器打开此TXT文件',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                  TextButton(
                    onPressed: () {
                      // 尝试打开文件所在目录
                      try {
                        Navigator.pop(context);
                        ToastMessage.show(
                          context,
                          '文件位置: $exportPath',
                          icon: Icons.folder_open,
                          backgroundColor: Colors.blue.withOpacity(0.9),
                        );
                      } catch (e) {
                        ToastMessage.show(
                          context,
                          '无法访问文件: $e',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                      }
                    },
                    child: const Text('查看位置'),
                  ),
                ],
              ),
        );

        // 显示提示
        ToastMessage.show(
          context,
          '数据已成功导出到手机下载目录：\n"下载/青禾记账/导出报表"文件夹',
          icon: Icons.file_download_done,
          backgroundColor: Colors.green.withOpacity(0.9),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('导出报表失败: $e');
      }

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误对话框
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('导出失败'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('导出过程中发生错误: $e'),
                    const SizedBox(height: 8),
                    const Text(
                      '请确保应用有足够的存储权限',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ],
              ),
        );

        // 显示提示
        ToastMessage.show(
          context,
          '导出失败: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    }
  }

  // 主题设置对话框
  void _showThemeSettingsDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    String selectedTheme;

    // 根据当前主题模式设置选中项
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        selectedTheme = l10n.lightTheme ?? '浅色';
        break;
      case ThemeMode.dark:
        selectedTheme = l10n.darkTheme ?? '深色';
        break;
      default:
        selectedTheme = l10n.defaultTheme ?? '默认';
    }

    final List<String> themeOptions = [
      l10n.defaultTheme ?? '默认',
      l10n.lightTheme ?? '浅色',
      l10n.darkTheme ?? '深色',
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Center(
                          child: Text(
                            l10n.themeSettings ?? '主题设置',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 显性风格选择
                        Text(
                          '显示模式',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...themeOptions.map(
                          (theme) => RadioListTile<String>(
                            title: Text(theme),
                            value: theme,
                            groupValue: selectedTheme,
                            activeColor: themeProvider.themeColor,
                            onChanged: (value) {
                              setState(() {
                                selectedTheme = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 主题颜色选择
                        Text(
                          '主题颜色',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 使用网格布局排列颜色选项
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: _buildColorGrid(themeProvider, setState),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // 操作按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel ?? '取消'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // 根据选择设置主题
                                ThemeMode newThemeMode;
                                if (selectedTheme ==
                                    (l10n.lightTheme ?? '浅色')) {
                                  newThemeMode = ThemeMode.light;
                                } else if (selectedTheme ==
                                    (l10n.darkTheme ?? '深色')) {
                                  newThemeMode = ThemeMode.dark;
                                } else {
                                  newThemeMode = ThemeMode.system;
                                }

                                // 更新主题
                                themeProvider.setThemeMode(newThemeMode);

                                // 使用新的ToastMessage替代SnackBar
                                ToastMessage.show(
                                  context,
                                  l10n.operationSuccess ?? '主题已更新',
                                  icon: Icons.check_circle_outline,
                                  backgroundColor: themeProvider.themeColor
                                      .withOpacity(0.9),
                                );

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.themeColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.save ?? '保存'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  // 构建颜色网格
  List<Widget> _buildColorGrid(
    ThemeProvider themeProvider,
    StateSetter setState,
  ) {
    // 将颜色按3列排列
    const int columnsCount = 3;
    final List<MapEntry<String, Color>> colorEntries =
        AppColors.themeColors.entries.toList();

    List<Widget> colorTiles = [];

    // 按行构建颜色选择器
    for (int i = 0; i < colorEntries.length; i += columnsCount) {
      for (int j = 0; j < columnsCount && i + j < colorEntries.length; j++) {
        final entry = colorEntries[i + j];
        final colorName = entry.key;
        final color = entry.value;
        final isSelected = themeProvider.themeColor.value == color.value;

        colorTiles.add(
          _buildColorTile(
            color: color,
            name: colorName,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                themeProvider.setThemeColor(color);
              });
            },
          ),
        );
      }
    }

    return colorTiles;
  }

  // 语言设置对话框
  void _showLanguageSettingsDialog() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context);

    // 根据当前语言设置选中项
    _selectedLanguage =
        languageProvider.locale.languageCode == 'en' ? 'English' : '简体中文';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final l10n = AppLocalizations.of(context);
              return AlertDialog(
                title: Text(l10n.languageSettings),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _languageOptions
                          .map(
                            (language) => RadioListTile<String>(
                              title: Text(language),
                              value: language,
                              groupValue: _selectedLanguage,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      // 根据选择设置语言
                      if (_selectedLanguage == 'English') {
                        languageProvider.setEnglish();
                      } else {
                        languageProvider.setChinese();
                      }

                      // 使用新的ToastMessage替代SnackBar
                      ToastMessage.show(
                        context,
                        '${l10n.languageSettings} ${l10n.operationSuccess}',
                        icon: Icons.check_circle_outline,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.9),
                      );

                      Navigator.pop(context);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('关于青禾记账'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('青禾记账是一款简单易用的个人记账应用。'),
                const SizedBox(height: 8),
                const Text('版本: 1.0.0'),
                const SizedBox(height: 8),
                const Text('开发者: Nagnip'),
                const SizedBox(height: 16),
                const Text(
                  '联系我们:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _launchUrl('mailto:xu814667@gmail.com'),
                  child: Text(
                    '邮箱: xu814667@gmail.com',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _launchUrl('https://example.com'),
                  child: Text(
                    '官方网站: example.com',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRatingDialog();
                },
                child: const Text('评分'),
              ),
            ],
          ),
    );
  }

  // 应用评分对话框
  void _showRatingDialog() {
    double rating = 5.0;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('为青禾记账评分'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('请为我们的应用评分，您的反馈对我们非常重要'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        return IconButton(
                          icon: Icon(
                            starValue <= rating
                                ? Icons.star
                                : Icons.star_border,
                            color:
                                starValue <= rating
                                    ? Colors.amber
                                    : Colors.grey,
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '您的反馈意见（可选）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      // 使用新的ToastMessage替代SnackBar
                      ToastMessage.show(
                        context,
                        '感谢您的${rating.toInt()}星评价！',
                        icon: Icons.star,
                        backgroundColor: Colors.amber.withOpacity(0.9),
                      );

                      Navigator.pop(context);
                    },
                    child: const Text('提交'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // 打开URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // 使用新的ToastMessage替代SnackBar
      ToastMessage.show(
        context,
        '无法打开 $url',
        icon: Icons.error_outline,
        backgroundColor: Colors.red.withOpacity(0.9),
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    // 使用新的ToastMessage替代SnackBar
    ToastMessage.show(
      context,
      message,
      icon: Icons.info_outline,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
    );
  }

  // 设置对话框方法保留但不再使用
  void _showSettingsDialog() {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isLoggedIn = userProvider.isLoggedIn;
    final l10n = AppLocalizations.of(context);

    // 直接跳转到设置页面
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // 显示退出登录确认对话框
  void _showLogoutDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认退出'),
            content: const Text('确定要退出登录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  userProvider.logout().then((_) {
                    // 使用新的ToastMessage替代SnackBar
                    ToastMessage.show(
                      context,
                      '已退出登录',
                      icon: Icons.exit_to_app,
                      backgroundColor: Colors.red.withOpacity(0.9),
                    );
                  });
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('退出'),
              ),
            ],
          ),
    );
  }

  void _showDocumentationHome(BuildContext context) {
    // 显示文档类别选择对话框
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDocumentationSheet(),
    );
  }

  Widget _buildDocumentationSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '帮助文档',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color:
                    isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDocumentItem(
                    title: '记账功能',
                    description: '了解如何使用各种方式快速记录您的收支',
                    icon: Icons.edit_note,
                    featureId: 'transaction_entry',
                  ),
                  _buildDocumentItem(
                    title: '统计分析',
                    description: '查看如何使用图表和数据分析您的财务状况',
                    icon: Icons.bar_chart,
                    featureId: 'statistics_analysis',
                  ),
                  _buildDocumentItem(
                    title: '分类预算',
                    description: '了解如何设置和管理不同支出类别的预算',
                    icon: Icons.category,
                    featureId: 'category_budget',
                  ),
                  _buildDocumentItem(
                    title: '月度预算',
                    description: '了解如何设置和管理月度总预算',
                    icon: Icons.account_balance_wallet,
                    featureId: 'monthly_budget',
                  ),
                  _buildDocumentItem(
                    title: '周期账单',
                    description: '设置自动重复的账单，如房租、订阅费等',
                    icon: Icons.repeat,
                    featureId: 'bill_recurring',
                  ),
                  _buildDocumentItem(
                    title: '云同步',
                    description: '了解如何在多设备间同步您的账单数据',
                    icon: Icons.cloud_sync,
                    featureId: 'cloud_sync',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String description,
    required IconData icon,
    required String featureId,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // 关闭底部菜单
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FeatureDocumentationScreen(featureId: featureId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

// BackupProgressDialog类 - 带进度条的备份对话框
class BackupProgressDialog extends StatefulWidget {
  final Function(String? backupPath) onComplete;
  final Function(dynamic error) onError;

  const BackupProgressDialog({
    super.key,
    required this.onComplete,
    required this.onError,
  });

  @override
  _BackupProgressDialogState createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<BackupProgressDialog> {
  double _progress = 0.0;
  String _statusMessage = '正在准备备份...';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startBackup();
  }

  Future<void> _startBackup() async {
    try {
      // 执行带进度报告的备份
      final backupPath = await BackupService.backupDatabaseWithProgress((
        progress,
      ) {
        setState(() {
          _progress = progress;

          // 根据进度更新状态消息
          if (progress < 0.3) {
            _statusMessage = '正在准备备份...';
          } else if (progress < 0.6) {
            _statusMessage = '正在读取数据...';
          } else if (progress < 0.8) {
            _statusMessage = '正在写入备份文件...';
          } else if (progress < 1.0) {
            _statusMessage = '正在完成备份...';
          } else {
            _statusMessage = '备份完成！';
            _isCompleted = true;
          }
        });
      });

      // 延迟一小段时间，确保用户能看到完成动画
      if (!_isCompleted) {
        setState(() {
          _progress = 1.0;
          _statusMessage = '备份完成！';
          _isCompleted = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // 关闭对话框并调用完成回调
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete(backupPath);
      }
    } catch (e) {
      // 发生错误时关闭对话框并调用错误回调
      if (mounted) {
        Navigator.of(context).pop();
        widget.onError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('数据备份'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度指示器
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _isCompleted ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // 状态消息
          Text(_statusMessage, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          // 进度文本
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              color:
                  _isCompleted ? Colors.green : Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 完成时的图标
          if (_isCompleted)
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 40,
            ),
        ],
      ),
      // 不提供取消按钮，防止用户中断备份过程
    );
  }
}

// RestoreProgressDialog类 - 带进度条的恢复对话框
class RestoreProgressDialog extends StatefulWidget {
  final String backupPath;
  final Function(bool success) onComplete;
  final Function(dynamic error) onError;

  const RestoreProgressDialog({
    super.key,
    required this.backupPath,
    required this.onComplete,
    required this.onError,
  });

  @override
  _RestoreProgressDialogState createState() => _RestoreProgressDialogState();
}

class _RestoreProgressDialogState extends State<RestoreProgressDialog> {
  double _progress = 0.0;
  String _statusMessage = '正在准备恢复...';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startRestore();
  }

  Future<void> _startRestore() async {
    try {
      // 执行带进度报告的恢复
      final success = await BackupService.restoreDatabaseWithProgress(
        widget.backupPath,
        (progress, message) {
          setState(() {
            _progress = progress;
            _statusMessage = message;

            if (progress >= 1.0) {
              _isCompleted = true;
            }
          });
        },
      );

      // 延迟一小段时间，确保用户能看到完成动画
      if (!_isCompleted) {
        setState(() {
          _progress = 1.0;
          _statusMessage = '恢复完成！';
          _isCompleted = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // 关闭对话框并调用完成回调
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete(success);
      }
    } catch (e) {
      // 发生错误时关闭对话框并调用错误回调
      if (mounted) {
        Navigator.of(context).pop();
        widget.onError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('数据恢复'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度指示器
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _isCompleted ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // 状态消息
          Text(_statusMessage, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          // 进度文本
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              color:
                  _isCompleted ? Colors.green : Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 完成时的图标
          if (_isCompleted)
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 40,
            ),
        ],
      ),
    );
  }
}

// 自定义备份选择对话框
class BackupSelectionDialog extends StatelessWidget {
  final List<FileSystemEntity> backupFiles;

  const BackupSelectionDialog({super.key, required this.backupFiles});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: const Center(
                child: Text(
                  '选择要恢复的备份',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 提示文本
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '从备份恢复将会覆盖现有数据。请选择要恢复的备份文件:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 备份文件列表
            Flexible(
              child:
                  backupFiles.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            '没有找到备份文件',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: backupFiles.length,
                        itemBuilder: (BuildContext context, int index) {
                          final file = backupFiles[index] as File;
                          final fileName = file.path.split('/').last;
                          DateTime? fileDate;

                          // 尝试从文件名提取日期 (格式: backup_yyyyMMdd_HHmmss.db)
                          try {
                            final regex = RegExp(r'backup_(\d{8})_(\d{6})\.db');
                            final match = regex.firstMatch(fileName);
                            if (match != null) {
                              final dateStr = match.group(1)!;
                              final timeStr = match.group(2)!;
                              fileDate = DateFormat(
                                'yyyyMMddHHmmss',
                              ).parse('$dateStr$timeStr');
                            } else {
                              fileDate = file.lastModifiedSync();
                            }
                          } catch (_) {
                            fileDate = file.lastModifiedSync();
                          }

                          final fileDateStr = DateFormat(
                            'yyyy-MM-dd',
                          ).format(fileDate);

                          final fileTimeStr = DateFormat(
                            'HH:mm:ss',
                          ).format(fileDate);

                          final fileSize = file.lengthSync();
                          final fileSizeStr =
                              fileSize < 1024 * 1024
                                  ? '${(fileSize / 1024).toStringAsFixed(2)} KB'
                                  : '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(
                                color: Colors.blue.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context, file.path);
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // 左侧图标
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.restore,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 中间信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileDateStr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fileTimeStr,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.storage,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                fileSizeStr,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 右侧箭头
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义颜色选择磁贴
Widget _buildColorTile({
  required Color color,
  required String name,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isSelected ? 0.6 : 0.4),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child:
              isSelected
                  ? Center(
                    child: Icon(Icons.check, color: Colors.white, size: 24),
                  )
                  : null,
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
