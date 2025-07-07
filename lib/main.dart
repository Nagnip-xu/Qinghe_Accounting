import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'constants/theme.dart';
import 'providers/account_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/financial_goal_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/account_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/budget_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'widgets/splash_screen.dart'; // 导入启动屏幕组件
import 'services/database_service.dart';
import 'database/database_helper.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定义全局导航键，用于在Provider中访问context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter引擎初始化

  // 初始化数据库
  await DatabaseHelper.instance.initDatabase();

  // 检查数据库是否刚刚被恢复
  await DatabaseHelper.instance.checkDatabaseRestored();

  // 初始化数据库服务
  final dbService = DatabaseService();
  final db = await dbService.database;

  // 检查并修复预算表结构
  try {
    print("检查预算表结构...");
    // 检查budgets表是否缺少categoryColor列
    var result = await db.rawQuery("PRAGMA table_info(budgets)");
    var columns = result.map((col) => col['name'] as String).toList();

    bool needsFix =
        !columns.contains('categoryColor') || !columns.contains('categoryIcon');

    if (needsFix) {
      print("发现预算表结构不完整，尝试修复...");
      // 创建临时表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets_temp(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          categoryId INTEGER,
          categoryName TEXT,
          categoryIcon TEXT,
          categoryColor TEXT,
          amount REAL NOT NULL,
          month TEXT NOT NULL,
          isMonthly INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
        )
      ''');

      // 复制数据
      await db.execute('''
        INSERT INTO budgets_temp(id, categoryId, categoryName, amount, month, isMonthly)
        SELECT id, categoryId, categoryName, amount, month, isMonthly FROM budgets
      ''');

      // 删除旧表
      await db.execute("DROP TABLE budgets");

      // 重命名新表
      await db.execute("ALTER TABLE budgets_temp RENAME TO budgets");

      print("预算表结构修复完成！");
    } else {
      print("预算表结构正常，无需修复");
    }
  } catch (e) {
    print("检查或修复预算表出错: $e");
  }

  // 初始化通知服务和恢复提醒，添加try-catch处理可能的异常
  try {
    final notificationService = NotificationService();
    
    // 初始化通知服务
    await notificationService.initialize();
    
    // 检查通知权限状态
    final hasPermission = await notificationService.hasPermission();
    print('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
    
    // 如果有权限，恢复提醒
    if (hasPermission) {
      await notificationService.restoreReminders();
      print('提醒已恢复');
    } else {
      print('无通知权限，跳过恢复提醒');
    }
  } catch (e) {
    print('通知服务初始化失败：$e');
    // 捕获异常但继续运行应用
  }

  // 运行应用
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FinancialGoalProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: languageProvider.getText('appTitle'),
            theme: AppTheme.createLightTheme(themeProvider.themeColor),
            darkTheme: AppTheme.createDarkTheme(themeProvider.themeColor),
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh'), Locale('en')],
            // 使用启动屏幕作为初始页面
            home: SplashScreen(
              nextScreen: const MainScreen(),
              duration: 2500, // 2.5秒后显示主屏幕
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 定义应用的主要页面
  final List<Widget> _pages = const [
    HomeScreen(), // 首页 - 索引0
    StatisticsScreen(), // 统计 - 索引1
    // 添加按钮没有对应页面（它会打开一个新页面）
    AccountScreen(), // 账户 - 索引2 (导航索引3)
    ProfileScreen(), // 我的 - 索引3 (导航索引4)
  ];

  @override
  void initState() {
    super.initState();
    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 检查是否数据库刚刚被恢复，以决定是否需要强制刷新数据
      bool forceRefresh = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastRestoreTime = prefs.getString('last_restore_time');
        if (lastRestoreTime != null) {
          // 有最近的恢复记录，检查是否是近期（10分钟内）恢复的
          final restoreTime = DateTime.parse(lastRestoreTime);
          final now = DateTime.now();
          final difference = now.difference(restoreTime);
          if (difference.inMinutes < 10) {
            // 是近期恢复的，强制刷新所有数据
            forceRefresh = true;
            print('检测到数据库刚刚被恢复，将强制刷新所有Provider数据');
            // 清除恢复时间记录，避免重复刷新
            await prefs.remove('last_restore_time');
          }
        }
      } catch (e) {
        print('检查数据库恢复状态时出错: $e');
      }

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
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 正常初始化或强制刷新
      if (forceRefresh) {
        // 如果是恢复后的强制刷新，打印提示
        print('强制刷新所有数据...');

        // 直接通过重新初始化实现刷新，不调用不存在的clearCache方法
        await Future.wait([
          userProvider.initialize(), // 确保用户信息最先初始化
          accountProvider.initAccounts(),
          transactionProvider.initData(),
          categoryProvider.initCategories(),
          budgetProvider.initBudgets(),
        ]);

        // 额外的数据同步
        syncAllData(context);
      } else {
        // 常规初始化 - 确保用户信息最先初始化
        await userProvider.initialize();
        print('用户信息初始化完成，登录状态: ${userProvider.isLoggedIn}');

        // 初始化其他提供者
        accountProvider.initAccounts();
        transactionProvider.initData();
        categoryProvider.initCategories();
        budgetProvider.initBudgets();

        // 添加一个延迟操作，确保所有数据都已加载完成后再次同步所有数据
        Future.delayed(const Duration(seconds: 2), () {
          syncAllData(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      // 页面索引转换为导航栏索引
      _currentIndex = index >= 2 ? index + 1 : index;
    });
  }

  void _onTabTapped(int index) {
    // 如果是添加按钮（索引2），启动添加交易页面
    if (index == 2) {
      // 不改变当前选中的导航项
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // 导航栏索引转换为页面索引
    int pageIndex = index > 2 ? index - 1 : index;

    // 获取当前页面索引
    int currentPageIndex =
        _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;

    // 判断是否是相邻页面
    bool isAdjacentPage = (pageIndex - currentPageIndex).abs() == 1;

    // 根据是否相邻选择切换方式
    if (isAdjacentPage) {
      // 相邻页面使用动画切换
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 非相邻页面直接跳转
      _pageController.jumpToPage(pageIndex);
    }
  }

  // 打开预算管理页面
  void _openBudgetScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BudgetScreen()));
  }

  // 全数据同步函数，用于确保所有数据一致性
  void syncAllData(BuildContext context) async {
    try {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      print('开始全面同步数据...');
      // 先强制同步账户余额
      await accountProvider.accountService.syncAccountBalances();
      // 再刷新账户提供者中的数据
      await accountProvider.syncData();
      // 刷新交易数据
      await transactionProvider.initData();

      print('所有数据同步完成！');
    } catch (e) {
      print('同步数据时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动翻页，只通过底部导航切换
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
